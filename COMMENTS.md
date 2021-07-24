## Alteração da API
Versão anterior da API usada dados em memória, que para simples teste de aplicabilidade funcionaria perfeitamente,
mas no nosso cenário há necessidade de implementação da API num cluster e por padrão não faz sentido publicar uma API
num cluster na qual tenhamos apenas um container em execução. Por esse motivo iremos salvar os dados no MondoDB.

## Publicação do Rancher
Usaremos ele para que fique mais simples a gestão e monitoramento do nosso cluster, por se tratar de um ambiente IaaS ele
nos fornece uma série de vantagens que é monitorarmos a saúde do nosso cluster.

## Usaremos uma VM simples para publicar nosso Rancher Server
Neste ponto usaremos a AWS, poderia ser qualquer provider, que teremos o mesmo resultado. Para criação dos ambientes usaremos
o Terraform, tendo em vista que no nosso cotidiano ele nos ajuda a produtizar o serviço de pedido de recursos. Neste caso uma
EC2 com determinadas características.