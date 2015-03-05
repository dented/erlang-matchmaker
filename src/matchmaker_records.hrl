% could prefix to ensure records are unique and not messed around by other objects by accident
-record(match, {id, team1=[], team2=[]}).
-record(player, {name="", wins=0, losses=0, mmr=1500}).
% -record(queue, {player})