# encoding: utf-8
module ExpressionSolver
  def self.solve(expr, base)
    unless expr.nil? or expr.blank?
      if expr.is_a? Numeric
        expr
      elsif expr.ends_with?('%')
        return if base.nil?
        Rails.logger.debug("ExpressionSolver: turning percentage (#{expr}) based on #{base}")
        base * expr.to_f / 100
      elsif expr.starts_with?('/')
        return if base.nil?
        Rails.logger.debug("ExpressionSolver: turning fractional (#{expr}) based on #{base}")
        base / expr[1..-1].to_i
      else
        Rails.logger.debug("ExpressionSolver: explicit number (#{expr}), base is #{base}")
        # ha a jobb oldalt ekzakt szammal adja meg a juzer, nem gondol az elojelre
        # nekunk kell leklonozni az input elojelet
        e = expr.to_i
        if base and ((base > 0 and e < 0) or (base < 0 and e > 0))
          -e
        else
          e
        end
      end
    end
  end

  module ClassMethods
    private

    def expression(attr, opts)
      define_method(attr) do
        expr = attributes[attr.to_s]
        base = send(opts[:base])
        Rails.logger.debug("Solving expression on attribute name '%s' value '%s'" % [attr, expr.inspect])
        ExpressionSolver.solve(expr, base)
      end
    end
  end

  def self.included(receiver)
    receiver.extend         ClassMethods
  end
end
