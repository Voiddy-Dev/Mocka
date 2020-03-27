// GEOMETRY PARAMS for all rockets
/** Position correspond to COM (center of mass)
 * All other attributes of the ship (hit points) are
 * given with respect to the COM. */
//float

// PHYSICS PARAMS for all rockets

float THRUST_VECTORING_MAXIMUM_DEFLECTION_ANGLE = radians(10);

abstract class Rocket {
  float x, y;
  float sx, sy;
}
