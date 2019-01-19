


function eg1()
    eg2(2)
end

function eg2(x)
    y=2x
    eg3(x,y)
end

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

