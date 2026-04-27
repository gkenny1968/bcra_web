require 'bundler/setup'
require 'sinatra'
require 'base_deudores_bcra'

# Configuración opcional para ver errores detallados en el navegador
set :show_exceptions, :after_handler

get '/' do
  erb :index
end

post '/consultar' do
  @cuit = params[:cuit]
  
  begin
    respuesta = BaseDeudoresBcra::BCRAClient.obtener_deuda(@cuit)
    
    # Imprimimos la clase del status para estar seguros en la terminal
    if respuesta
      puts "DEBUG: La clase de status es #{respuesta['status'].class}" 
    end

    # Usamos .to_i para que no importe si es "200" o 200
    if respuesta && respuesta["status"].to_i == 200 && respuesta["results"]
      results = respuesta["results"]
      @nombre = results["denominacion"]
      
      # Navegamos la estructura
      if results["periodos"] && !results["periodos"].empty?
        primer_periodo = results["periodos"].first
        @periodo_nombre = primer_periodo["periodo"]
        @deudas = primer_periodo["entidades"]
      else
        @error = "No hay períodos informados para este CUIT."
      end
    else
      # Si falla, mostramos qué devolvió exactamente para no adivinar
      @error = "Respuesta inesperada del BCRA (Status: #{respuesta['status'] if respuesta})."
    end
  rescue => e
    @error = "Error en el procesamiento: #{e.message}"
  end

  erb :index
end
