import { createHelia, HeliaLibp2p } from 'helia'
import { useState, useEffect, createContext } from 'react'

// TODO: i think I need an IpfsContext here in order to use "helia" in the app

export const Ipfs = () => {
  const [id, setId] = useState<string | null>(null)
  const [helia, setHelia] = useState<HeliaLibp2p | null>(null)
  const [isOnline, setIsOnline] = useState(false)

  useEffect(() => {
    const init = async () => {
      if (helia) return

      const heliaNode = await createHelia()

      const nodeId = heliaNode.libp2p.peerId.toString()
      const nodeIsOnline = heliaNode.libp2p.status === 'started'

      setHelia(heliaNode)
      setId(nodeId)
      setIsOnline(nodeIsOnline)
    }

    init()
  }, [helia])

  if (!helia || !id) {
    return <h4>Starting Helia...</h4>
  }

  return (
    <div>
      <h4 data-test="id">IPFS ID: {id.toString()}</h4>
      <h4 data-test="status">IPFS Status: {isOnline ? 'Online' : 'Offline'}</h4>
    </div>
  )
}
