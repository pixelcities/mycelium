import * as DOMPurify from "dompurify"

const decrypt = async (data, key) => {
  const { aes_gcm_siv_decrypt } = await import("key-x-wasm")

  return aes_gcm_siv_decrypt(data, key)
}

window.render = (id, key) => {
  const iframe = document.getElementById(id);
  const data = iframe.getAttribute("data");

  if (key) {
    decrypt(data, key).then((decrypted) => {
      iframe.srcdoc = DOMPurify.sanitize(decrypted);
    })

  } else {
    iframe.srcdoc = DOMPurify.sanitize(atob(data));
  }
}

