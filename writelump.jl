

#### write to files


open("lumped_"*filename, "w") do f
  write(f, "{Lumping $(filename) using lumper.jl tool. D.Ellis 2017\n\n")


  write(f,"Add defns to constants file \n")

nlumped = length(collect(Base.flatten(lumplist)))


  write(f,"\n\nSpecies - Lumping combinations are : \n\n")

  for i in enumerate(lumplist)
    write(f, " LMP$i \n")
  end


  write(f,"}\n\n")

  m = open(filename);
  for ln in eachline(m)
    #println("$(length(ln)), $ln")
    write(f, ln*"")
    if contains(ln,"DEFVAR")
      p("stop")
      break
    end
  end
  close(m)

  writespecs = []
  for x in specs
    try
      x = "LMP$(lumpdict[x])"
    end
    push!(writespecs,x)
  end
  writespecs = (unique(writespecs,1))
  sort!(writespecs)


  for s in writespecs
    if s != "DUMMY"
      write(f, "$s = IGNORE;\n")
    end
  end







#greater than 80 characters




  write(f, """#INLINE F90_RCONST
  USE constants
  USE lumpedrates
  ! end of USE statements
  ! start of executable statements

  """)

write(f,"Real(dp)::PA($(nlumped))\n")
write(f,"Real(dp)::LC($(nlumped))\n")
write(f,"Integer::index\n")





  write(f,join(ppair,"\n    "))




    write(f, """\n\n
    do index = 1, $(nlumped)
      if (isnan(LC(index))) LC(index) = 0
    end do
    """)






  write(f, "\n\nRO2 = 0 ")

  ro2 = sort([replace(x,"ind_","") for x in  matchall(r"ind_(\w+)\b", join(lines) ) ])
  #groupspecs = collect(Base.flatten(lumplist))
  for i in 1:length(ro2)

    try
      ro2[i] = "C(IND_LMP$(lumpspec[ro2[i]])) * LC($(lumpspec[ro2[i]]))"
    catch
      ro2[i] = "C(IND_$(ro2[i]))"
    end
    write(f, "&\n+ $(ro2[i]) ")

  end



  write(f, """\n\n    CALL mcm_constants(time, temp, M, N2, O2, RO2, H2O)
  #ENDINLINE """)


  write(f,"\n\n#EQUATIONS\n")

  for i in enumerate(eqns)

    rt = i[2][4]
    #rt = tostr(sympy.N(sympy.expand(replace(i[2][4],r"(\d)D([\+\-\d])",s"\1E\2")),3))

    rt = replace(rt,r"EXP\(([-\d\.]+)/TEMP\)",s"ET(\1)")
    rt = replace(rt,r"LC_(\d)_",s"LC(\1)")
    write(f,"{$(i[1])} $(i[2][2]) = $(i[2][3]) : $(rt);\n")
  end




end


run(`scp ./lumped_methanecomplete.kpp dp626@earth0:~/DSMACC-testing/mechanisms/autolump.kpp`)

"""
module lumpedrates
USE model_Precision, ONLY: dp
use constants
IMPLICIT NONE

contains
 FUNCTION ET(a)
    USE model_global, only: TEMP
    real(dp) :: ET
    INTEGER    :: a
    ET = EXP(a/TEMP)
 END FUNCTION



end module lumpedrates
"""
