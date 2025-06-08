@include src/shaders/header.glsl

@vs vs
@include src/shaders/common_vs2.glsl

layout(location = 0) in vec3 high;
layout(location = 1) in vec3 low;
void main(){
  vec4 p = translateRelativeToEye(high,low);
  gl_Position = modelViewProjectionRelativeToEye * p;
}

@end

@fs fs
out vec4 frag_color;

void main() {
  frag_color = vec4(1.0,0.0,0.0,1.0);
}
@end

@program scene vs fs