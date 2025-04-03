import Section from "../Section";
import '../../App.css'
import Label from "../Label";

export default function AboutMe({className=""}) {

    const labels = [
        'Unity', 'Godot', 'OpenGL', 'C', 'C++', 
        'JavaScript', 'Python', 'C#', 'ASP .NET',
        'Flask', 'React JS', 'Vue JS', 'React Native', 'MySQL', 'SQLite3'
    ]

    return(
        <>
            <Section className={className} title='About Me'>
                <p>
                I started as a Unity game developer, learning programming through CS50x and game/web projects. In 2024, I delved into OpenGL and graphics programming to build a game engine. I also learned ASP.NET and React.js to expand into full-stack development.
                </p>
            </Section>
            <Section className={className} title='Tech'>
                <div>
                <ul style={{display: "flex", flexWrap: "wrap", listStyle: "none", padding: 0, gap: "10px"}}>
                    {labels.map((label, index) => {
                        return (
                            <li key={index}>
                                <Label content={label}/>
                            </li>
                        )
                    })}
                </ul>
                </div>
            </Section>
        </>
    )
}