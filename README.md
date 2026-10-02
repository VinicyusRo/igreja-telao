# Assembleia de Deus – Ministério Madureira

Site para celebrar os aniversariantes da semana, registrar visitantes e exibir tudo no telão durante o culto. Dados e login no Supabase.

## Arquivos
- `index.html`: o site inteiro
- `supabase-setup.sql`: tabelas e regras de acesso (rodar no SQL Editor do Supabase)

## Perfis
- admin: tudo | recepcao: edita visitantes | midia: edita avisos | telao: só leitura
- Todos veem telão, aniversários e membros. As regras valem no servidor (RLS).

## Publicar
GitHub Pages: Settings > Pages > branch main, pasta / (root).
A URL e a publishable key do Supabase podem ficar no código. NUNCA coloque a secret key nem senhas.
