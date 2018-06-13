# DatabaseProject
Final work for BD2

link for ER (anyone with link can edit)
https://drive.google.com/file/d/15QH-lgESRlu7iv7rPD7OBSW9nS9RBZPu/view?usp=sharing




Triggers

1 - Deletar um usuário da tabela de seguidores ao bloqueá-lo.

2 - Gerar mensagem de REQUISIÇÃO de chat quando um não seguidor te manda mensagem. 

3 - Tornar as mensagens visíveis quando o usuário ACEITA receber mensagens daquele usuário

4 - Ao PEDIR para seguir um usuário PRIVADO, é adicionado na tabela desse usuário, uma linha USUÁRIOS PENDENTES.

5- Ao aceitar o pedido de SEGUIR, removemos o usuário dessa tabela, e adicionamos na tabela de seguidores.


OO das entidades:

-Usuário(id, login, password, nome, descrição, seguidores, seguindo, mídia, caixa de mensagens)

-Mídia: (id, conteudo,tipo de mídia, marcações, localização)
    tipo de mídia: vídeo, imagem ou gif 

Mídia duradoura(legenda, curtidas, comentários)
        
Mídia temporária(alcance)
alcance: postar no perfil ou lista de usuários específicos

-Comentários(curtidas)
