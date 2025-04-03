export default function SectionWrapper({selected = false , children}) {
    return(
        <div className={`section ${selected ? 'selected-section' : ''}`} style={{flex: 1, display: 'flex'}}>
            {children}
        </div>
    )
}