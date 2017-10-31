
include("deflump.jl")

filename = "methanecomplete.kpp"

f = open(filename)
lines = [replace(ln,r"[;\h]+","") for ln in split(replace(readstring(f),r":\h*\n",":"),"\n")]
eqns = [split(eq,r"[\}=:]") for eq in filter(x->ismatch(r"\{[\d\.]+\}", x), lines)]

specs = Set(vcat(pmap(getspecs,eqns)...))
nspecs = length(specs)

#rate number dictionary
rated = Set([r[4] for r in eqns])
r_rated = Dict(zip(UInt32(1):UInt32(length(rated)),rated))
rated = Dict(zip(rated,UInt32(1):UInt32(length(rated))))

#spec dicionary
specd = Dict(zip(specs,UInt32(1):UInt32(length(specs))))
rspec = Dict(zip(UInt32(1):UInt32(length(specs)),specs))

@eval @everywhere rated=$rated
@eval @everywhere specd=$specd

#each eq numbered
eqnum = pmap(numerate,eqns)
@eval @everywhere eqnum=$eqnum

###############################

lumplist = [["CH3O2","CH3O2NO2"],["HCHO","CH3O"]]
#lumplist = [["CH3O2","CH3O2NO2"]]
#lumplist = [["CL"]]#,["HCHO","CH3O"]]


pspecs = [specd[x] for x in collect(Base.flatten(lumplist))]
parr = pmap(production_array,pspecs)
parr = Dict(zip(pspecs,parr))


lumpdict = []
lumpspec = []
  ppair = []

counter = 1
for pairing in enumerate(lumplist)
  for j in pairing[2]
    push!(lumpdict, [j,pairing[1]] )
    push!(lumpspec, [j,counter] )
    counter +=1
  end
end

  @eval @everywhere lumpspec =  Dict(lumpspec)
lumpdict = Dict(lumpdict)




for element in enumerate(lumplist)

  @eval @everywhere pnum = $element[1]
  pairing = element[2]
  p(pairing)

  pair = [specd[i] for i in pairing]


  #a-> b :r  if l->l ignore . Therefore ignore and cancel in normal eqnum
  p(pair)


  push!(ppair, "\n! LMP$(pnum): "*join(["$(lumpspec[i]) -> $i" for i in pairing], ", ")*"\n")

  for n in 1:length(pair)
    i = pair[n]
    temp = "0"
    for j in parr[i]
      s = ""
      self = false
      for k in j[1][1]
        if k != "1"
          s = s * k *"*"
        end
      end
      for k in j[2][1]
        #if k in pair
          #self = true
          #break
        #end
        try
          s=s * "C(ind_LMP$(lumpdict[rspec[k]]))*LC_$(lumpspec[rspec[k]])_*"
        catch
          s=s * "C(ind_"* rspec[k] * ")*"
        end
      end
      s=s * r_rated[j[3]]
      #if self == false
        temp = temp*"+"*s*""
      #end
    end



    thisspec = rspec[i]
    thisno = lumpspec[thisspec]

    #temp = replace(tostr(sympy.N(sympy.expand(replace(temp,r"(\d)D([\+\-\d])",s"\1E\2")),3)),"+","&\n      +")
    temp = replace(temp,"+","&\n      +")



    temp = replace(temp,r"EXP\(([-\d\.]+)/TEMP\)",s"ET(\1)")
    temp = replace(temp,r"LC_(\d)_",s"LC(\1)")
    push!(ppair, "PA($(thisno))="*temp)

    push!(ppair, "LC($(thisno)) =  PA($(thisno))/("*join(["PA($(lumpspec[rspec[e]]))" for e in pair],"+")*")")

  end


  @eval @everywhere pgroup=$pairing

  eqns = pmap(replace_match,eqns)

end




include("writelump.jl")





x= 1
