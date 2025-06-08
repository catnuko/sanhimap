
layout(binding=0) uniform vs_common{
  vec3 encodedCameraPositionMCHigh;
  vec3 encodedCameraPositionMCLow;
  mat4 modelViewProjectionRelativeToEye;
  mat4 projection;
  mat4 modelView;
  mat4 modelViewRelativeToEye;
};

vec4 translateRelativeToEye(vec3 high, vec3 low)
{
    vec3 highDifference = high - encodedCameraPositionMCHigh;
    // This check handles the case when NaN values have gotten into `highDifference`.
    // Such a thing could happen on devices running iOS.
    if (length(highDifference) == 0.0) {  
        highDifference = vec3(0);  
    }
    vec3 lowDifference = low - encodedCameraPositionMCLow;

    return vec4(highDifference + lowDifference, 1.0);
}

