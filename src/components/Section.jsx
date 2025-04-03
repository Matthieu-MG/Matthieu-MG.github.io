import '../App.css'

export default function Section({title='Title', className="", children}) {
    return (
        <div className={`content ${className}`}>

            <h2 className='poiret-one-regular header'>{title}</h2>
            
            {children}

        </div>
    )
}