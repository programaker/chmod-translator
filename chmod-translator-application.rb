require "chmod-translator"

class ChmodTranslatorApplication
    def self.run
        if block_given?
            begin
                chmod = yield
                puts chmod.to_s << " = " << chmod.translate
            rescue ChmodTranslationError => e
                puts ">>> #{e.message}"
            rescue Exception => e
                puts ">>> ocorreu um erro inesperado: #{e.message}"    
            end
        end
    end
end
