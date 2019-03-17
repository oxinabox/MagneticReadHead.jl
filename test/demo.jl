function eg1()
    z = eg2(2)
    eg_last(z)
end

eg_last(x) = x

function eg2(x)
    y=eg21(x)
    ret = eg3(x,y)
    y = 1 + y
    return ret
end

eg21(x) = 2x

function eg3(a,b)
    a+b
end
############

function egerr()
    egerr2(2)
end

function egerr2(x)
    y=2x
    egerr3(x,y)
end

function egerr3(a,b)
    error(a)
end

