import AboutMe from "./Sections/AboutMe";
import Contact from "./Sections/Contact";
import Projects from "./Sections/Projects";
import '../App.css'

export default function ScrollableView() {
    return (
        <div className="scroll">
            <div style={{margin: "2em 5%"}}>
                <div id='name'>
                <h1 className='gravitas-one-regular' style={{fontSize: "2.5em", opacity: 1, color: 'white'}}>Matthieu Gaudet</h1>
                </div>
                <h1 className='gravitas-one-regular animated-title' style={{fontSize: "2.5em"}}>Matthieu Gaudet</h1>
                <AboutMe/>
                <Projects/>
                <Contact/>
            </div>
        </div>
    )
}