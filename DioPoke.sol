// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0; // Especifica a versão do compilador Solidity a ser utilizada

// Importa o contrato ERC721 padrão da OpenZeppelin
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Define o contrato PokeDIO que herda do contrato ERC721
contract PokeDIO is ERC721 {

    // Define a estrutura para armazenar as informações dos Pokémons
    struct Pokemon {
        string name;   // Nome do Pokémon
        uint level;    // Nível do Pokémon
        string img;    // URL da imagem do Pokémon
    }

    // Array público que armazena todos os Pokémons
    Pokemon[] public pokemons;

    // Endereço do proprietário do jogo
    address public gameOwner;

    // Construtor do contrato, define o nome e o símbolo do token e o dono do jogo
    constructor() ERC721("PokeDIO", "PKD") {
        gameOwner = msg.sender; // Define o criador do contrato como o dono do jogo
    }

    // Modificador que restringe o acesso a funções para apenas o proprietário do Pokémon
    modifier onlyOwnerOf(uint _monsterId) {
        require(ownerOf(_monsterId) == msg.sender, "Apenas o dono pode batalhar com este Pokemon");
        _; // Continua a execução da função modificada
    }

    // Evento para registrar batalhas
    event BattleResult(uint indexed attackerId, uint indexed defenderId, uint attackerNewLevel, uint defenderNewLevel);

    // Mapeamento para armazenar a última vez que um Pokémon batalhou
    mapping(uint => uint) public lastBattleTime;

    // Constante para definir o tempo mínimo entre batalhas (1 dia em segundos)
    uint constant BATTLE_COOLDOWN = 1 days;

    // Função modificada para batalha com cooldown
    function battle(uint _attackingPokemon, uint _defendingPokemon) public onlyOwnerOf(_attackingPokemon) {
        require(block.timestamp >= lastBattleTime[_attackingPokemon] + BATTLE_COOLDOWN, "Pokemon precisa descansar antes da proxima batalha");
        
        Pokemon storage attacker = pokemons[_attackingPokemon];
        Pokemon storage defender = pokemons[_defendingPokemon];

        // Compara os níveis dos Pokémons e ajusta os níveis após a batalha
        if (attacker.level >= defender.level) {
            attacker.level += 2; // O atacante ganha 2 níveis
            defender.level += 1; // O defensor ganha 1 nível
        } else {
            attacker.level += 1; // O atacante ganha 1 nível
            defender.level += 2; // O defensor ganha 2 níveis
        }

        // Atualiza o tempo da última batalha
        lastBattleTime[_attackingPokemon] = block.timestamp;

        // Emite o evento com o resultado da batalha
        emit BattleResult(_attackingPokemon, _defendingPokemon, attacker.level, defender.level);
    }

    // Função para criar um novo Pokémon e mintar um token ERC721 para ele
    function createNewPokemon(string memory _name, address _to, string memory _img) public {
        require(msg.sender == gameOwner, "Apenas o dono do jogo pode criar novos Pokemons");
        uint id = pokemons.length; // O ID do novo Pokémon é o comprimento atual do array
        pokemons.push(Pokemon(_name, 1, _img)); // Adiciona o novo Pokémon ao array
        _safeMint(_to, id); // Mint o token para o endereço fornecido
    }

    // Nova função para evoluir um Pokémon
    function evolvePokemon(uint _pokemonId) public onlyOwnerOf(_pokemonId) {
        Pokemon storage pokemon = pokemons[_pokemonId];
        require(pokemon.level >= 10, "Pokemon precisa estar no nivel 10 ou maior para evoluir");
        
        pokemon.level += 5;
        pokemon.name = string(abi.encodePacked(pokemon.name, " Evoluido"));
    }
}