# possiveis erros
class ChmodTranslationError < Exception; end

class InvalidOctalError < ChmodTranslationError
    def initialize(octal)
        super("#{octal} não é um octal válido")
    end
end

class InvalidTextError < ChmodTranslationError
    def initialize(text)
        super("#{text} não é uma permissão válida")
    end
end


# recebe as permissoes como texto e traduz para octal
class TextChmodTranslator
private
    def process_permitions(permitions)
        if permitions && permitions.size == 3 && permitions.match(/[r-][w-][x-]/)
            permitions
        else
            "---"
        end
    end

    def add_permitions(permitions)
        list = [0, 0, 0]
    
        if permitions && permitions.size == 3
            list[0] = (permitions[0] == ?r ? 1 : 0)
            list[1] = (permitions[1] == ?w ? 1 : 0)
            list[2] = (permitions[2] == ?x ? 1 : 0)
        end
        
        list
    end
    
    def octal_value(list)
        i = -1
        
        octal = list.reverse.inject(0) do |sum, n| 
            i += 1
            sum + n * (2 ** i)
        end
        
        octal.to_s
    end
public
    def initialize(text)
        is_valid_text = text &&
            text.size == 9 &&
            text =~ /([r-][w-][x-]){3}/
            
        raise InvalidTextError.new(text) unless is_valid_text
    
        owner = text[0..2]
        group = text[3..5]
        others = text[6..8]
        
        @owner = process_permitions owner
        @group = process_permitions group
        @others = process_permitions others
    end
    
    def to_s
        "#{@owner}#{@group}#{@others}"
    end
    
    def translate
        owner = add_permitions @owner
        group = add_permitions @group
        others = add_permitions @others
    
        octal_owner = octal_value owner
        octal_group = octal_value group
        octal_others = octal_value others
        
        "#{octal_owner}#{octal_group}#{octal_others}"
    end
end


# recebe as permissões em octal e traduz para texto
class OctalChmodTranslator
private
    def number_to_binary(number)
        n = number.chr.to_s.to_i
        binary = ""
        
        # faz divisões sucessivas por 2 e guarda os restos
        while n > 0
            binary << (n % 2).to_s
            n = n / 2
        end
        
        # o número binário é formado pelos restos da
        # divisão por 2 de traz para frente
        binary.reverse!
        
        # completa o binário com zeros à esquerda de forma
        # a manter o numero sempre com 3 algarismos
        "%03d" % binary.to_i
    end
    
    def binary_to_permitions(binary)
        permitions = ""
        
        permitions << (binary[0] == ?1 ? "r" : "-")
        permitions << (binary[1] == ?1 ? "w" : "-")
        permitions << (binary[2] == ?1 ? "x" : "-")
        
        permitions
    end
public
    def initialize(octal)
        is_valid_octal = octal &&
            octal.to_i.between?(0, 777) && 
            octal.size == 3 && 
            octal =~ /[0-7][0-7][0-7]/
    
        raise InvalidOctalError.new(octal) unless is_valid_octal     
        @octal = octal
    end

    def to_s
        # esta interpolação é para criar uma cópia não frozen do atributo string
        "#{@octal}"
    end
    
    def translate
        owner_binary = number_to_binary @octal[0]
        group_binary = number_to_binary @octal[1]
        others_binary = number_to_binary @octal[2]
        
        owner_permitions = binary_to_permitions owner_binary
        group_permitions = binary_to_permitions group_binary
        others_permitions = binary_to_permitions others_binary
    
        "#{owner_permitions}#{group_permitions}#{others_permitions}"
    end
end


# façade para os chmod translators
class ChmodTranslator
    @@chmod_translator = nil
    
    def self.from_text(text)
        @@chmod_translator = TextChmodTranslator.new(text)
        @@chmod_translator
    end
    
    def self.from_octal(octal)
        @@chmod_translator = OctalChmodTranslator.new(octal)        
        @@chmod_translator
    end

    def self.to_octal(text)
        from_text(text).translate
    end
    
    def self.to_text(octal)
        from_octal(octal).translate
    end
end
