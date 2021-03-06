-module(matchmaker).
-include("matchmaker_records.hrl").
-include_lib("stdlib/include/qlc.hrl").
-export([install/1, start/2, stop/1]).

-export([enter_queue/1,enter_queue/4, player_by_name/1, find_match/1, lookup_players_in_queue/0]).

install(Nodes) ->
    ok = mnesia:create_schema(Nodes),
    rpc:multicall(Nodes, application, start, [mnesia]),
    mnesia:create_table(player,
                        [{attributes, record_info(fields, player)},
                        {index, [#player.mmr]},
                        {disc_copies, Nodes}]),
    mnesia:create_table(match,
                        [{attributes, record_info(fields, match)},
                        {index, [#match.id]},
                        {disc_copies, Nodes}]),
    rpc:multicall(Nodes, application, stop, [mnesia]).

start(normal, []) ->
    mnesia:wait_for_tables([match, player], 5000),
    matchmaker_sup:start_link().

stop(_) -> ok.

% Testing out functions
enter_queue(Name, Wins, Losses, Mmr) ->
    enter_queue(#player{name=Name, wins=Wins, losses=Losses, mmr=Mmr}).

enter_queue(Player) ->
    F = fun() ->
            mnesia:write(Player)
    end,
    mnesia:activity(transaction, F).

% Find a match by team size 3v3 / 5v5
find_match(3) ->
    PlayersInQueue = lookup_players_in_queue(),
    sort_players(PlayersInQueue);
    % sort_players(Players);
find_match(5) ->
    false;
find_match(_) ->
    undefined.

lookup_players_in_queue() ->
    F = fun() ->
        Q = qlc:q([{P#player.name,P#player.mmr} || P <- mnesia:table(player)],{cache, list}),
        qlc:e(Q)
    end,
    mnesia:transaction(F).

% Find Player by Name
player_by_name(Name) ->
    F = fun() ->
        case mnesia:read({player, Name}) of
            [#player{wins=W, losses=L, mmr=M}] ->
                {Name,W,L,M};
            [] ->
                undefined
        end
    end,
    mnesia:activity(transaction, F).

%%%%% PRIVATE %%%%%

% Sorting players by MMR
% todo: traverse list of players to find next range
sort_players(InQueue) ->
    % F = fun() when in_list(K) ->
    % maps:map(F, players)
    Players = maps:from_list(element(2, InQueue)),
    Players.

% sort_players(Player) ->
%     lookup_players_in_queue_in_mmr_range(element(2,Player)).

% Players by MMR with an overhead of 100 and less of 50 to ensure players
% are not always playing in range of each other but not much worse than another
lookup_players_in_queue_in_mmr_range(Mmr) ->
    F = fun() ->
        Q = qlc:q([P#player.name || P <- mnesia:table(player),
                                    P#player.mmr >= Mmr - 50,
                                    P#player.mmr =< Mmr + 100]),
        qlc:e(Q)
    end,
    mnesia:transaction(F).

