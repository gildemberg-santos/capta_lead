FROM ruby:3.4.4

WORKDIR /app

# Dependências do sistema para pg e node (se necessário futuramente)
RUN apt-get update -qq && apt-get install -y -qq build-essential libpq-dev postgresql-client && rm -rf /var/lib/apt/lists/*

# Instala gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copia o código da aplicação
COPY . .

# Porta do Puma
EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
