import ProjectBox from "../ProjectBox";
import Section from "../Section";
import '../../App.css'
import { useEffect, useState } from "react";

export default function Projects({className=""}) {
    const [hoveredIndex, setHoveredIndex] = useState(0);

    const projects = [
        {
            name: "Water Sim",
            repository: "https://github.com/Matthieu-MG/Water-Simple-Gerstner-Waves-Simulation",
            content: (
                <>
                    <p>
                    A Water Simulation made in OpenGL and C++. 
                    </p>
                    <p>
                    Based from GPU Gems 1 Article and and ShaderToy's implementations on water shading
                    </p>
                </>
            )
        },
        {
            name: "3D Renderer",
            content: (                
                <>
                    <p>
                    A 3D Renderer made in OpenGL and C++. 
                    </p>
                    <p>
                        Performs Model Loading and Rendering, Framebuffer Manipulation, Tesselation and more.
                    </p>
                </>
            )
        },
        {
            name: "Wellness",
            repository: "https://github.com/Matthieu-MG/Wellness",
            content: (                
                <>
                    <p>
                    Medical and Fitness Mobile App made in React Native and Expo. 
                    </p>
                    <p>
                        Record treatments and get notified when you need to take them.
                        Set up your workout routine and get your fitness going!
                    </p>
                </>
            )
        },
        {
            name: "E-Commerce",
            repository: "https://github.com/Matthieu-MG/Item_Harvest",
            content: (                
                <>
                    <p>
                    My First Project: made in Flask and Python.
                    </p>
                    <p>
                        Allows user to search and browse Ebay's products via their API, add them to wishlist.
                        Converts prices to local currency.
                        Features user accounts.
                    </p>
                </>
            )
        }
    ]

    useEffect(() => {

    }, [])

    return (
        <Section className={className} title="Projects">
            <div id="projects">
                <ul style={{listStyle: "none", display: "flex", flexDirection: "column", gap: "10px"}}>
                    {projects.map( (p, index) => 
                    <li key={index} onMouseEnter={() => setHoveredIndex(index)} className="project-box">{p.name}</li>)}
                </ul>
                <aside style={{padding: "0 1em"}}>
                    {projects[hoveredIndex].content}
                    {projects[hoveredIndex].repository && 
                        <button className="repository-btn" onClick={() => open(projects[hoveredIndex].repository)}>Repository</button>}
                </aside>
            </div>
        </Section>
    )
}