modules.libraries.matrix = {}

function modules.libraries.matrix:toOrientation(m)
    -- Mapping flat indices (Column-Major)
    local i, j, k
    i={x=m[1], y=m[2], z=m[3]} -- Column 1 (I vector)
    j={x=m[5], y=m[6], z=m[7]} -- Column 2 (J vector)
    k={x=m[9], y=m[10], z=m[11]} -- Column 3 (K vector)

    local a=math.atan(k.x,k.z)

    local tjz,tjx=self:rotmat2d(j.z,j.x,-a)
    local tkz,tkx=self:rotmat2d(k.z,k.x,-a)

    local e=math.atan(k.y,tkz)

    local tjz,tjy=self:rotmat2d(tjz,j.y,-e)
    local tkz,tky=self:rotmat2d(tkz,k.y,-e)

    local r=math.atan(tjx,tjy)

    return a, e, r
end

function modules.libraries.matrix:rotmat2d(x, y, r)
    return x*math.cos(r)-y*math.sin(r), x*math.sin(r)+y*math.cos(r)
end

function modules.libraries.matrix:fromOrientation(yaw, pitch, roll)
    -- yaw, pitch, roll -> Quaternion
    local sr, cr, sp, cp, sy, cy =
    math.sin(roll * 0.5),
    math.cos(roll * 0.5),
    math.sin(pitch * 0.5),
    math.cos(pitch * 0.5),
    math.sin(yaw * 0.5),
    math.cos(yaw * 0.5)
    local q = {
        X = cy * sp * cr + sy * cp * sr,
        Y = sy * cp * cr - cy * sp * sr,
        Z = cy * cp * sr - sy * sp * cr,
        W = cy * cp * cr + sy * sp * sr
    }

    -- Quaternion -> Matrix
    local xx = q.X ^ 2
    local yy = q.Y ^ 2
    local zz = q.Z ^ 2
    local xy = q.X * q.Y
    local wz = q.Z * q.W
    local xz = q.Z * q.X
    local wy = q.Y * q.W
    local yz = q.Y * q.Z
    local wx = q.X * q.W
    return self:new({
        1 - 2 * (yy + zz),	2 * (xy + wz),		2 * (xz - wy),		0,
        2 * (xy - wz),		1 - 2 * (zz + xx),	2 * (yz + wx),		0,
        2 * (xz + wy),		2 * (yz - wx),		1 - 2 * (yy + xx),	0,
        0,					0,					0, 					1
    })
end

function modules.libraries.matrix:new(...)
    local input = {...}
    local matrix = {}
    if #input > 0 and #input[1] == 16 then
        matrix = input[1]
    else
        for i=1,4 do
            for j=1,4 do
                matrix[(i-1)*4+j] = input[i] and (input[i][j] or input[i][({"x", "y", "z"})[j]]) or 0
            end
        end
    end
    return matrix
end