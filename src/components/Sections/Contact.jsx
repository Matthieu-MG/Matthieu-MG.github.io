import Section from "../Section";
import { FaGithub, FaLinkedin, FaEnvelope, FaInstagram } from 'react-icons/fa'

export default function Contact({className=""}) {
    const iconSize = 40;
    const iconColor = 'white'

    return (
        <Section className={className} title="Contact">
            <div className="grid">
                <a href="https://github.com/Matthieu-MG" target="_blank" rel="noopener noreferrer">
                    <FaGithub className="icon" size={iconSize} color={iconColor} />
                </a>
                <a href="https://linkedin.com/in/matthieu-gaudet-741100328" target="_blank" rel="noopener noreferrer">
                    <FaLinkedin className="icon" size={iconSize} color={iconColor} />
                </a>
                <a href="mailto:matthieu.loic@icloud.com">
                    <FaEnvelope className="icon" size={iconSize} color={iconColor}/>
                </a>
                <a href="https://instagram.com/matthieu_6g">
                    <FaInstagram className="icon" size={iconSize} color={iconColor} />
                </a>
            </div>
        </Section>
    )
}