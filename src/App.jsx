import { useEffect, useRef, useState } from 'react'
import './App.css'
import { InitWebGL, ResizeCanvas, RenderRaymarcher, TestClientGPU, IsLowEndGPU } from './utils/canvas';
import Section from './components/section';
import AboutMe from './components/Sections/AboutMe';
import Projects from './components/Sections/Projects';
import SectionWrapper from './components/SectionWrapper';
import Contact from './components/Sections/Contact';
import ScrollableView from './components/ScrollableView';

function App() {
  const canvasRef = useRef(null);
  const scrollCooldown = useRef(false);
  const [selected, setSelected] = useState(0);

  const [isDesktop, setIsDesktop] = useState(true);

  const contents = [
    <AboutMe className='ms-1' selected={true}/>, <Projects className='ms-1'/>, <Contact className='ms-1'/>
  ]

  const checkIfDesktop = () => {
    const isDesktopNow = !(window.innerWidth < 910 || window.innerHeight < 630);
    //* Prevents unnecessary re-renders
    if (isDesktop !== isDesktopNow) {
      setIsDesktop(isDesktopNow);
    }
  }
  checkIfDesktop();

  const handleScroll = (event) => {
    if (scrollCooldown.current) return;

    scrollCooldown.current = true;

    const currentScrollY = event.deltaY;

    if(true) {
      setSelected(prevSelected => {
        let newIndex = prevSelected + (currentScrollY < 0 ? -1 : 1);
        
        if (newIndex < 0) return 0;
        if (newIndex >= contents.length) return contents.length - 1;
  
        return newIndex;
      });
    }

    setTimeout(() => {
      scrollCooldown.current = false; // Reset cooldown after 1000ms
    }, 1000);
  }

  useEffect(() => {
    //! If InitWebGL fails or device cannot run it, the default background color will serve as background
    const gl = InitWebGL(canvasRef.current);
    let canRender = false;

    if(gl) {
      canRender = !IsLowEndGPU(gl);
      console.log("Can Render: ", canRender);

      if(canRender && TestClientGPU(gl)) {
        RenderRaymarcher(gl, canvasRef.current);
      }
    }

    //* Resize to proper resolution for rendering, so as not to use a too big framebuffer
    const resizeGLViewport = () => { 
      if(canRender && gl !== null) {
        ResizeCanvas(canvasRef.current, gl)
      }; 
    };

    window.addEventListener('wheel', handleScroll);
    window.addEventListener('resize', checkIfDesktop);
    window.addEventListener('resize', resizeGLViewport)

    return () => {
      window.removeEventListener('wheel', handleScroll);
      window.removeEventListener('resize', checkIfDesktop);
      window.removeEventListener('resize', resizeGLViewport); 
    }
  }, []);

  return (
    <>
      <canvas ref={canvasRef} id='raymarcher'/>
      {/* Container for actual html elements */}
      <div id='main'>
        { !isDesktop ? <ScrollableView/> : 
        <>
          <div id='name'>
            <h1 className='gravitas-one-regular' style={{fontSize: "2.5em", opacity: 1, color: 'white'}}>Matthieu Gaudet</h1>
          </div>
            <h1 className='gravitas-one-regular animated-title' style={{fontSize: "2.5em"}}>Matthieu Gaudet</h1>
          <div className='container'>
            <main className='card'>
              {contents.map((c, index) => {
                return(
                  <SectionWrapper key={index} selected={index === selected}>
                    {c}
                  </SectionWrapper>
                )
              })}
              <button id='next-btn' onClick={() => setSelected( (selected + 1) % contents.length)}><h2>{'>'}</h2></button>
            </main>
            <div>
              <ul className='nav-ul'>
                {contents.map((c, index) => <li key={index} className={`nav-li ${index === selected ? 'nav-selected-li' : ''}`}/>)}
              </ul>
            </div>
          </div>
        </>
        }
      </div>
    </>
  )
}

export default App
