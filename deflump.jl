@everywhere using PyCall
@everywhere @pyimport sympy
tostr = py"lambda x: str(x)"

nocoeff= r"\b[^\W]*(\w+)\b"
bothcoeff= r"\b(\d*)(\w+)\b"
mspec= r"\b(\w+)\b"


p=println


@everywhere function getspecs(x)
  # Functions return the value of their last statement
  dummy = x[2]*"="*x[3]
  matchall(nocoeff,dummy)
end

@everywhere function nums(i)
  specd[match(bothcoeff,i)[2]]
end


@everywhere function coeff(i)
  dummy = match(bothcoeff,i)[1]
  if dummy == ""
    dummy = "1"
  end
  dummy
end

@everywhere function numerate(x)
  # Functions return the value of their last statement
  react = matchall(mspec,x[2])
  prods = matchall(mspec,x[3])
  [[[ coeff(i) for i in react],[coeff(i) for i in prods]],[[nums(i) for i in react],[nums(i) for i in prods]],rated[x[4]]]
end


@everywhere function production_array(marked)
  dummy = []
  for row in eqnum
    if marked in row[2][2]
      push!(dummy,row)
    end
  end
  return dummy
end



@everywhere function replace_match(ln)
  #eq = ln[2]*"="*ln[3]
  for j in pgroup
    re = Regex("\\b\\d{0,2}"*j*"\\b")
    if ismatch(re,ln[3])
      ln[3] = replace(ln[3],re,"LMP$(pnum)")
    end
    if ismatch(re,ln[2])
      ln[2] = replace(ln[2],re,"LMP$(pnum)")
      ln[4]=ln[4]*"*LC_$(lumpspec[j])_"
      p(ln[4])
    end
  end
  #ln[4] = tostr(sympy.N(sympy.expand(replace(ln[4],r"(\d)D([\+\-\d])",s"\1E\2")),3))
  return ln
end
