// Adjust only framebuffer resolution: all geometry, expressions and clips stay intact.
export class MobileQuality {
  constructor() { this.scale = 1; this.reset(); }
  reset() { this.elapsed = 0; this.frames = 0; this.fastWindows = 0; }
  pixelRatio(width, height, dpr = 1) {
    return Math.min(Math.max(1, dpr), 2, 2048 / Math.max(width, height),
      Math.sqrt(2000000 / (width * height))) * this.scale;
  }
  sample(seconds) {
    if (!(seconds > 0) || seconds > .25) return false;
    this.elapsed += seconds; this.frames++;
    if (this.elapsed < 3) return false;
    const fps = this.frames / this.elapsed;
    this.elapsed = 0; this.frames = 0;
    const previous = this.scale;
    if (fps < 45) { this.scale = Math.max(.6, this.scale - .1); this.fastWindows = 0; }
    else if (fps > 57) {
      if (++this.fastWindows >= 4) { this.scale = Math.min(1, this.scale + .05); this.fastWindows = 0; }
    } else this.fastWindows = 0;
    return Math.abs(previous - this.scale) > .001;
  }
}
