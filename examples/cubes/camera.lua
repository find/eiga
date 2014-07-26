local glProj = function(fov, aspect, zn, zf)
    local ys = math.tan( math.pi/2 - fov/2 )
    local xs = ys / aspect

    return mat4( xs,  0,         0       ,  0,
                  0, ys,         0       ,  0,
                  0,  0, (zf+zn)/(zf-zn) , -1,
                  0,  0, -2*zf*zn/(zf-zn),  0)
end

local Camera = class('Camera')
Camera.initialize = function(self, eye, at, up)
    self.eye = eye or vec3(0,0,-1)
    self.at  = at  or self.eye+vec3(0,0,1)
    self.up  = up  or vec3(0,1,0)
    self.fov = math.pi/3
    self.aspect = 1.0
    self.near = 1.0
    self.far  = 500
end

Camera.view = function(self)
    return mat4.lookAtRH(self.eye, self.at, self.up)
end

Camera.proj = function(self)
    return mat4.perspectiveFovRH(self.fov, self.aspect, self.near, self.far)
end

return Camera

