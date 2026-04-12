import { useState, useEffect, useRef, type ReactNode, type MouseEvent as ReactMouseEvent, type KeyboardEvent, type ChangeEvent } from 'react'
import './index.css'

// A simple draggable window component
type WindowPosition = {
  x: number
  y: number
}

type DraggableWindowProps = {
  title: string
  children: ReactNode
  onClose: () => void
  initialPos: WindowPosition
}

const DraggableWindow = ({ title, children, onClose, initialPos }: DraggableWindowProps) => {
  const [pos, setPos] = useState(initialPos)
  const [isDragging, setIsDragging] = useState(false)
  const dragRef = useRef<WindowPosition | null>(null)

  const handleMouseDown = (e: ReactMouseEvent<HTMLDivElement>) => {
    setIsDragging(true)
    dragRef.current = { x: e.clientX - pos.x, y: e.clientY - pos.y }
  }

  const handleMouseMove = (e: MouseEvent) => {
    if (isDragging && dragRef.current) {
      setPos({
        x: e.clientX - dragRef.current.x,
        y: e.clientY - dragRef.current.y
      })
    }
  }

  const handleMouseUp = () => setIsDragging(false)

  useEffect(() => {
    if (isDragging) {
      window.addEventListener('mousemove', handleMouseMove)
      window.addEventListener('mouseup', handleMouseUp)
    } else {
      window.removeEventListener('mousemove', handleMouseMove)
      window.removeEventListener('mouseup', handleMouseUp)
    }
    return () => {
      window.removeEventListener('mousemove', handleMouseMove)
      window.removeEventListener('mouseup', handleMouseUp)
    }
  }, [isDragging])

  return (
    <div 
      className="absolute glassmorphism flex flex-col overflow-hidden"
      style={{ left: pos.x, top: pos.y, width: '600px', height: '400px' }}
    >
      {/* Title Bar */}
      <div 
        className="h-10 bg-black/40 border-b border-white/20 flex justify-between items-center px-4 cursor-move select-none"
        onMouseDown={handleMouseDown}
      >
        <div className="font-semibold text-sm tracking-wider text-blue-300 uppercase">{title}</div>
        <button onClick={onClose} className="text-red-400 hover:text-red-300 font-bold px-2">X</button>
      </div>
      
      {/* Content */}
      <div className="flex-1 p-4 overflow-y-auto font-mono text-sm text-green-400">
        {children}
      </div>
    </div>
  )
}

function App() {
  const kernelUrl = import.meta.env.VITE_KERNEL_URL ?? "ws://localhost:8765"
  const [terminalOpen, setTerminalOpen] = useState(true)
  const [logs, setLogs] = useState(["[RippleOS Kernel Booted]", "Connection to Jipple Engine established."])
  const [input, setInput] = useState("")
  const [ws, setWs] = useState<WebSocket | null>(null)
  
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    // Connect to the Python Kernel Server
    const socket = new WebSocket(kernelUrl)
    
    socket.onopen = () => {
      setLogs(prev => [...prev, `[WebSocket] Connected to ${kernelUrl}`])
    }
    
    socket.onmessage = (event) => {
      const data = JSON.parse(event.data)
      if (data.status === "success") {
        setLogs(prev => [...prev, `[System]: ${data.response}`])
      } else {
        setLogs(prev => [...prev, `[ERROR]: ${data.response}`])
      }
    }
    
    setWs(socket)
    
    return () => socket.close()
  }, [kernelUrl])

  useEffect(() => {
    // Auto-scroll terminal
    bottomRef.current?.scrollIntoView({ behavior: "smooth" })
  }, [logs])

  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' && input.trim()) {
      setLogs(prev => [...prev, `[User]: ${input}`])
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ input }))
      } else {
        setLogs(prev => [...prev, "[ERROR]: Kernel disconnected. Cannot reach Jipple VM."])
      }
      setInput("")
    }
  }

  return (
    <div className="w-screen h-screen relative">
      {/* Desktop Area */}
      <div className="absolute inset-0 p-8 flex flex-col gap-6">
        <div 
          className="w-24 h-24 glassmorphism flex flex-col items-center justify-center cursor-pointer hover:bg-white/20 transition-colors"
          onClick={() => setTerminalOpen(true)}
        >
          <div className="text-4xl">🌊</div>
          <div className="text-xs mt-2 font-medium">Jipple Term</div>
        </div>
      </div>

      {/* Windows */}
      {terminalOpen && (
        <DraggableWindow title="Jipple Terminal v1.0.0" onClose={() => setTerminalOpen(false)} initialPos={{x: 200, y: 100}}>
          <div className="flex flex-col gap-2 min-h-full">
            <div className="flex-1 whitespace-pre-wrap">
              {logs.map((log, i) => (
                <div key={i} className={log.includes("[ERROR]") ? "text-red-400" : (log.includes("[System]") ? "text-cyan-300" : "")}>
                  {log}
                </div>
              ))}
              <div ref={bottomRef} />
            </div>
            <div className="flex items-center border-t border-white/10 pt-2 mt-2">
              <span className="text-blue-500 mr-2">ripple@sys:~$</span>
              <input 
                type="text" 
                value={input}
                onChange={(e: ChangeEvent<HTMLInputElement>) => setInput(e.target.value)}
                onKeyDown={handleKeyDown}
                className="flex-1 bg-transparent outline-none border-none text-green-400"
                autoFocus
              />
            </div>
          </div>
        </DraggableWindow>
      )}

      {/* Taskbar */}
      <div className="absolute bottom-0 left-0 right-0 h-12 glassmorphism rounded-none border-x-0 border-b-0 flex items-center px-4 justify-center">
        <div className="flex gap-4">
          <div 
            className={`px-4 py-1 rounded-lg cursor-pointer transition-colors ${terminalOpen ? 'bg-white/20' : 'hover:bg-white/10'}`}
            onClick={() => setTerminalOpen(!terminalOpen)}
          >
            🌊 RippleOS
          </div>
        </div>
      </div>
    </div>
  )
}

export default App
