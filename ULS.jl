using JuMP, GLPKMathProgInterface
Zmin = 1000000
function GetMax(Dem,Cst1::Vector{Int32},Cst2::Vector{Int32})
  ToOne = 0.0
  Indice::Int32 = -1
  for i = 1:1:5
    if Dem[i] > ToOne && Cst1[i] == 0 && Cst2[i] == 1
      ToOne = Dem[i]
      Indice = i
    end
  end
  return Indice
end
function BranchAndBound(indiceY::Int32,Cst1::Vector{Int32},Cst2::Vector{Int32})
  #PREMEIR ARRAY >= Cst1
  #SECOND ARRAY <= Cst2
  if indiceY == -1
    return
  end
  global Zmin

  Cst1[indiceY] =  1
  Cst2[indiceY] = 1
  Ztemp,y = GetNewModel(Cst1,Cst2)
  if !isnan(Ztemp)
    if !isinteger(Ztemp)
      if Ztemp < Zmin
        BranchAndBound(y,Cst1,Cst2)
      end
    elseif Ztemp < Zmin
      println("NEW INTEGER SOLUTION : ",Ztemp)
      Zmin=Ztemp
    end
  end

  Cst1[indiceY] = 0
  Cst2[indiceY] = 0

  Ztemp,y = GetNewModel(Cst1,Cst2)

  if !isnan(Ztemp)
    if !isinteger(Ztemp)
      if Ztemp < Zmin
        BranchAndBound(y,Cst1,Cst2)
      end
    elseif Ztemp < Zmin
      println("NEW INTEGER SOLUTION : ",Ztemp)
      Zmin=Ztemp
    end
  end

end


function main()
  global Zmin
  CstBB1::Vector{Int32}         = [0,0,0,0,0]
  CstBB2::Vector{Int32}         = [1,1,1,1,1]
  Ztemp,ToOne = GetNewModel(CstBB1,CstBB2)

  BranchAndBound(ToOne,CstBB1,CstBB2)
  println(Zmin)
end
function GetNewModel(CstBB1::Vector{Int32},CstBB2::Vector{Int32})
  nbvar=5
  m                 = Model(solver=GLPKSolverLP())
  GrandM            = 100
  demande           = [3,5,6,3,8]
  stockage          = [3,2,3,2]
  demarage          = [10,8,6,4,2]
  production        = [2,4,6,8,10]

  @variable(   m , Prod[1:nbvar] >=0)
  @variable(m, Stock[1:nbvar-1] >=0)
  @variable(m,0<= Dem[1:nbvar] <=1)
  @objective(  m , Min, sum(Dem[j]*demarage[j]+ production[j] * Prod[j]  for j=1:nbvar ) + sum( Stock[i] * stockage[i] for i=1:nbvar-1) )

  @constraint(m,cteder,Prod[1] == demande[1]+Stock[1])
  @constraint( m , cte[i=2:nbvar-1], sum(Prod[i]+Stock[i-1]) == demande[i]+Stock[i] )
  @constraint(m,ctedere,Prod[nbvar] + Stock[nbvar-1] == demande[nbvar])
  @constraint(m,entrepot[i=1:nbvar],Prod[i] <=Dem[i]*GrandM)
  @constraint(m,Dem1[i=1:nbvar],Dem[i] >= CstBB1[i])
  @constraint(m,Dem2[i=1:nbvar],Dem[i] <= CstBB2[i])

  solve(m)
  fx = getobjectivevalue(m)
  println("f(x) = ",fx)
  if !isnan(fx)
    res1=getvalue(Dem)
    ToOne = GetMax(res1,CstBB1,CstBB2)
  else
    ToOne = 0
  end
  #println(m)
  return fx,ToOne
end

main()
