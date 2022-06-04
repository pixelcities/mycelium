extern crate base64;

use futures::executor::block_on;

use rand::rngs::OsRng;
use key_x_wasm::libsignal_protocol::*;
use key_x_wasm::PreKeyBundleSerde;


/// Encrypt a single message for the given user
///
/// This is meant for one time messages only. The identity and store
/// of the sender are not persisted in any way, which means that the
/// session cannot live past this single exchange.
///
/// The caller should take care of retrieving and deleting the bundle.
///
/// The practical use of a single message from a random untrusted agent
/// is limited, but it simulates the interactions between real users.
/// This function is currently used to exchange a (known) metadata key
/// between new users and an agent managing a trial data space.
///
/// TODO: Persist state, so that the trial agent may be trusted
#[rustler::nif]
fn encrypt_once(user_id: String, user_bundle: String, message: String) -> String {
    block_on(async move {
        let mut csprng = OsRng;

        let identity_key = IdentityKeyPair::generate(&mut csprng);
        let mut store = InMemSignalProtocolStore::new(identity_key, 1).unwrap();

        let address = ProtocolAddress::new(user_id.clone(), 1);
        let pre_key_bundle: PreKeyBundle = PreKeyBundleSerde::deserialize(&base64::decode(&user_bundle).unwrap()[..]).into();

        process_prekey_bundle(
            &address,
            &mut store.session_store,
            &mut store.identity_store,
            &pre_key_bundle,
            &mut csprng,
            None,
        ).await.unwrap();

        let encrypted = message_encrypt(message.as_bytes(), &address, &mut store.session_store, &mut store.identity_store, None).await.unwrap();

        base64::encode(&encrypted.serialize())
    })
}


rustler::init!("Elixir.KeyX.Protocol.Agent", [encrypt_once]);
