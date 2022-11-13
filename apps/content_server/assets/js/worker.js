const local = {}

const decrypt = async (data, key) => {
  const { aes_gcm_siv_decrypt } = await import("key-x-wasm")

  return aes_gcm_siv_decrypt(data, key)
}

onmessage = ({ data: { action, payload }}) => {
  if (action === "saveKey") {
    local.key = payload

    postMessage({
      action: "keySaved"
    })

  } else if (action === "render") {
    if (payload.isPublic === "1") {
      postMessage({
        action: "render",
        id: payload.id,
        data: atob(payload.data)
      })

    } else if (!!local.key && payload.data.indexOf(":") !== -1) {
      decrypt(payload.data, local.key).then(decrypted => {
        postMessage({
          action: "render",
          id: payload.id,
          data: decrypted
        })
      })
    }
  }
}

