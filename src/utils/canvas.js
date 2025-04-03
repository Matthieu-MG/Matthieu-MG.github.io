import fSource from "../assets/fragment.glsl?raw"
import vSource from "../assets/vertex.glsl?raw"

export {InitWebGL, RenderRaymarcher, ResizeCanvas, TestClientGPU, IsLowEndGPU}

function InitWebGL(canvas) {
    console.log("Canvas: ", canvas);
    const gl = canvas.getContext("webgl2");
    ResizeCanvas(canvas, gl);
    
    if(!gl) {
        console.error("Could Not Get WebGL2 Context - Exiting..");
        return null;
    }
    return gl;
}

function RenderRaymarcher(gl, canvas) {
    const program = initShaderProgram(gl);

    if(!program) {
        console.error("Could Not Initialize Shader Program - Exiting..");
        return null;
    }

    const {vbo, vao} = initVao(gl);

    if(!vao) {
        console.error("Could Not Initialize VAO - Exiting..")
        return null;
    }

    const uniforms = [
        {
            name: "iTime",
            value: 0
        }
    ]

    //* render loop
    render(gl, program, vao, uniforms, canvas);
}

function ResizeCanvas(canvas, gl) {
    const dpr = window.devicePixelRatio || 1;
    canvas.width = canvas.clientWidth * dpr;
    canvas.height = canvas.clientHeight * dpr;
    gl.viewport(0, 0, canvas.width, canvas.height);
}

function TestClientGPU(gl) {
    const start = performance.now();
    for (let i = 0; i < 1000000; i++) {
        gl.clear(gl.COLOR_BUFFER_BIT);
    }
    const end = performance.now();

    console.log(`start ${start}, end ${end}, diff ${end - start}`);
    
    return (end - start < 200); // If it takes too long, fallback
}

function IsLowEndGPU(gl) {
    const lowEndGPUs = [
        "intel uhd", "intel hd", "iris", 
        "radeon vega", "gt 710", "gt 730", "gt 1030", 
        "radeon r5", "radeon r7", "mali", "adreno", "powervr"
    ]

    const gpuName = GetClientGPUDetails(gl).gpuVendor.toLowerCase();

    return lowEndGPUs.some((gpu) => gpuName.includes(gpu));
}

function GetClientGPUDetails(gl) {
    const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
    if (debugInfo) {
        const gpuVendor = gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL) || "";
        const gpuRenderer = gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL) || "";
        return { gpuVendor, gpuRenderer };
    }
    return { gpuVendor:"", gpuRenderer:"" };
}

function render(gl, program, vao, uniforms, canvas) {
    let then = 0;
    const renderLoop = (now) => {
        now *= 0.001; //* converts to seconds
        const deltaTime = now - then;
        then = now;

        gl.clearColor(1.0, 0.0, 0.0, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);
    
        gl.useProgram(program);
        setUniform1f(gl, program, "iTime", now);
        setUniform2f(gl, program, "iResolution", canvas.width, canvas.height);
        gl.bindVertexArray(vao);
        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

        requestAnimationFrame(renderLoop);
    }

    requestAnimationFrame(renderLoop);
}

function initVao(gl) {

    const vao = gl.createVertexArray();
    gl.bindVertexArray(vao);

    const vbo = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);

    const vertexData = [
        -1.0, -1.0, 0.0, 0.0, // Bottom Left
         1.0, -1.0, 1.0, 0.0, // Bottom Right 
        -1.0,  1.0, 0.0, 1.0, // Top Left
         1.0,  1.0, 1.0, 1.0, // Top Right
    ]

    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertexData), gl.STATIC_DRAW);

    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 16, 0);
    gl.enableVertexAttribArray(1);
    gl.vertexAttribPointer(1, 2, gl.FLOAT, false, 16, 8);

    gl.bindVertexArray(null);

    return {
        vao: vao,
        vbo: vbo
    }
}

function initShaderProgram(gl) {
    const vShader = loadShader(gl, gl.VERTEX_SHADER, vSource);
    const fShader = loadShader(gl, gl.FRAGMENT_SHADER, fSource);

    const program = gl.createProgram();
    gl.attachShader(program, vShader);
    gl.attachShader(program, fShader);
    gl.linkProgram(program);

    if(!gl.getProgramParameter(program, gl.LINK_STATUS)) {
        console.error('Unable to initialize shader program: ', gl.getProgramInfoLog(program));
        return null;
    }

    return program;
}

function loadShader(gl, type, source) {
    const shader = gl.createShader(type);
  
    // Send the source to the shader object
    gl.shaderSource(shader, source);
  
    // Compile the shader program
    gl.compileShader(shader);
  
    // See if it compiled successfully
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      console.error(
        `An error occurred compiling the shaders: ${gl.getShaderInfoLog(shader)}`,
      );
      gl.deleteShader(shader);
      return null;
    }
  
    return shader;
}

function setUniform2f(gl, program, name, x, y) {
    const resolutionLocation = gl.getUniformLocation(program, name);
    gl.uniform2f(resolutionLocation, x, y);
}

function setUniform1f(gl, program, name, x) {
    const resolutionLocation = gl.getUniformLocation(program, name);
    gl.uniform1f(resolutionLocation, x);
}