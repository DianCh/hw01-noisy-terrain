import {vec2, vec4, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';

var activeProgram: WebGLProgram = null;

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  prog: WebGLProgram;

  attrPos: number;
  attrNor: number;
  attrCol: number;

  unifModel: WebGLUniformLocation;                                                // 1. declare handle
  unifModelInvTr: WebGLUniformLocation;
  unifViewProj: WebGLUniformLocation;
  unifColor: WebGLUniformLocation;
  unifPlanePos: WebGLUniformLocation;
  unifOCTAVE  : WebGLUniformLocation;
  unifFreq    : WebGLUniformLocation;
  unifLac     : WebGLUniformLocation;
  unifAmp     : WebGLUniformLocation;
  unifGain    : WebGLUniformLocation;
  unifLayer   : WebGLUniformLocation;
  unifTerr    : WebGLUniformLocation;
  unifCellSize: WebGLUniformLocation;
  unifExp     : WebGLUniformLocation;
  unifMul     : WebGLUniformLocation;

  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");
    this.attrNor = gl.getAttribLocation(this.prog, "vs_Nor");
    this.attrCol = gl.getAttribLocation(this.prog, "vs_Col");
    this.unifModel      = gl.getUniformLocation(this.prog, "u_Model");              // 2. get handle from shaders
    this.unifModelInvTr = gl.getUniformLocation(this.prog, "u_ModelInvTr");
    this.unifViewProj   = gl.getUniformLocation(this.prog, "u_ViewProj");
    this.unifPlanePos   = gl.getUniformLocation(this.prog, "u_PlanePos");
    this.unifOCTAVE     = gl.getUniformLocation(this.prog, "u_OCTAVE");
    this.unifFreq       = gl.getUniformLocation(this.prog, "u_Frequency");
    this.unifLac        = gl.getUniformLocation(this.prog, "u_Lacunarity");
    this.unifAmp        = gl.getUniformLocation(this.prog, "u_Amplitude");
    this.unifGain       = gl.getUniformLocation(this.prog, "u_Gain");
    this.unifLayer      = gl.getUniformLocation(this.prog, "u_Layer");
    this.unifTerr       = gl.getUniformLocation(this.prog, "u_Terrain");
    this.unifCellSize   = gl.getUniformLocation(this.prog, "u_CellSize");
    this.unifExp        = gl.getUniformLocation(this.prog, "u_Exponent");
    this.unifMul        = gl.getUniformLocation(this.prog, "u_Multiply");
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

  setModelMatrix(model: mat4) {
    this.use();
    if (this.unifModel !== -1) {
      gl.uniformMatrix4fv(this.unifModel, false, model);
    }

    if (this.unifModelInvTr !== -1) {
      let modelinvtr: mat4 = mat4.create();
      mat4.transpose(modelinvtr, model);
      mat4.invert(modelinvtr, modelinvtr);
      gl.uniformMatrix4fv(this.unifModelInvTr, false, modelinvtr);
    }
  }

  setViewProjMatrix(vp: mat4) {
    this.use();
    if (this.unifViewProj !== -1) {
      gl.uniformMatrix4fv(this.unifViewProj, false, vp);
    }
  }

  setPlanePos(pos: vec2) {
    this.use();
    if (this.unifPlanePos !== -1) {
      gl.uniform2fv(this.unifPlanePos, pos);
    }
  }

  setOctave(o: number) {                      // 3. pass the value to the uniform value
    this.use();
    if (this.unifOCTAVE !== -1) {
      gl.uniform1i(this.unifOCTAVE, o);
    }
  }

  setFrequncey(f: number) {
    this.use();
    if (this.unifFreq !== -1) {
      gl.uniform1f(this.unifFreq, f);
    }
  }

  setLacunarity(l: number) {
    this.use();
    if (this.unifLac !== -1) {
      gl.uniform1f(this.unifLac, l);
    }
  }

  setAmplitude(a: number) {
    this.use();
    if (this.unifAmp !== -1) {
      gl.uniform1f(this.unifAmp, a);
    }
  }

  setGain(g: number) {
    this.use();
    if (this.unifGain !== -1) {
      gl.uniform1f(this.unifGain, g);
    }
  }

  setLayer(l: number) {
    this.use();
    if (this.unifLayer !== -1) {
      gl.uniform1i(this.unifLayer, l);
    }
  }

  setTerr(t: number) {
    this.use();
    if (this.unifTerr !== -1) {
      gl.uniform1i(this.unifTerr, t);
    }
  }

  setCellSize(c: number) {
    this.use();
    if (this.unifCellSize !== -1) {
      gl.uniform1i(this.unifCellSize, c);
    }
  }

  setExp(e: number) {
    this.use();
    if (this.unifExp !== -1) {
      gl.uniform1f(this.unifExp, e);
    }
  }

  setMul(m: number) {
    this.use();
    if (this.unifMul !== -1) {
      gl.uniform1f(this.unifMul, m);
    }
  }

  draw(d: Drawable) {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrNor != -1 && d.bindNor()) {
      gl.enableVertexAttribArray(this.attrNor);
      gl.vertexAttribPointer(this.attrNor, 4, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);
    if (this.attrNor != -1) gl.disableVertexAttribArray(this.attrNor);
  }
};

export default ShaderProgram;
