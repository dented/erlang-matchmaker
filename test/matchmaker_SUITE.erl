-module (matchmaker_SUITE).
-include_lib("common_test/include/ct.hrl").
-include("../src/matchmaker_records.hrl").
-export([init_per_suite/1, end_per_suite/1, init_per_testcase/2, end_per_testcase/2, all/0]).

-export([enter_queue/1,enter_queue_as_record/1,get_players_in_queue/1,find_match_three_v_three/1]).

all() -> [enter_queue,enter_queue_as_record,get_players_in_queue,find_match_three_v_three].

init_per_suite(Config) ->
    Priv = ?config(priv_dir, Config),
    application:set_env(mnesia, dir, Priv),
    matchmaker:install([node()]),
    application:start(mnesia),
    application:start(matchmaker),
    Config.

end_per_suite(_Config) ->
    application:stop(mnesia),
    ok.

init_per_testcase(enter_queue, Config) ->
    ok = matchmaker:enter_queue("A", 1, 10, 1230),
    ok = matchmaker:enter_queue("B", 2, 1, 1530),
    ok = matchmaker:enter_queue("C", 5, 3, 1630),
    ok = matchmaker:enter_queue("D", 1, 3, 1430),
    ok = matchmaker:enter_queue("E", 30, 5, 1730),
    ok = matchmaker:enter_queue("F", 7, 2, 1590),
    ok = matchmaker:enter_queue("G", 3, 10, 1330),
    ok = matchmaker:enter_queue("H", 10, 3, 1630),
    ok = matchmaker:enter_queue("I", 10, 7, 1530),
    ok = matchmaker:enter_queue("J", 1, 3, 1450),
    ok = matchmaker:enter_queue("K", 5, 3, 1610),
    Config;
init_per_testcase(enter_queue_as_record, Config) ->
    Config;
init_per_testcase(get_players_in_queue, Config) ->
    Config;
init_per_testcase(find_match_three_v_three, Config) ->
    Config;
init_per_testcase(find_match_five_v_five, Config) ->
    Config.

end_per_testcase(_, _Config) ->
    ok.

enter_queue(_Config) ->
    ok = matchmaker:enter_queue("Gram", 50, 3, 1630),
    {"Gram", _Win, _Losses, _Mmr} = matchmaker:player_by_name("Gram"),
    undefined = matchmaker:player_by_name(make_ref()).

enter_queue_as_record(_Config) ->
    ok = matchmaker:enter_queue(#player{name="Gram Player",wins=50,losses=3,mmr=1630}),
    {"Gram Player", 50, 3, 1630} = matchmaker:player_by_name("Gram Player"),
    undefined = matchmaker:player_by_name(make_ref()).

get_players_in_queue(_Config) ->
    {atomic,[1500,1500,1500,1500,1530,1520,1500]} = matchmaker:lookup_players_in_queue(),
    failed = matchmaker:lookup_players_in_queue().

find_match_three_v_three(_Config) ->
    match_found = matchmaker:find_match(3),
    undefined = matchmaker:find_match(make_ref()).

% find_match_five_v_five(_Config) ->
%     match_found = matchmaker:find_match(5),
%     undefined = matchmaker:find_match(make_ref()).