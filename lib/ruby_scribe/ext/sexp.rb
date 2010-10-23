class Sexp
  def kind
    sexp_type.to_sym
  end
  
  def body
    sexp_body
  end
end