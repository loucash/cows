%%%-------------------------------------------------------------------
%%% @doc Middleware for http basic auth.
%%%
%%% Opts = [{user, <<"username">>}, {pass, <<"password">>}]
%%% BasicAuth = {http_basic_auth_required, Opts}
%%% Routes = [{<<"/some/resource">>, some_resource_handler, [BasicAuth]}]
%%% cowboy_router:compile([{'_', Routes}]) and so on..
%%%
%%% Handler receives logged in user in HandlerOpt (init(HandlerOpt)) as
%%% [{http_basic_auth_user, User}, BasicAuth]
%%%
%%% If there is no http_basic_auth_required atom, request always passes
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(cows_basic_auth_middleware).

-behaviour(cowboy_middleware).

-export([execute/2]).

-define(HTTP_BASIC_AUTH_USER, http_basic_auth_user).

execute(Req, Env) ->
    case cowboy_req:method(Req) of
        {<<"OPTIONS">>, Req2} ->
            {ok, Req2, Env};
        {_, Req2} ->
            check_basic_auth(Req2, Env)
    end.

-spec check_basic_auth(cowboy_req:req(), cowboy_middleware:env()) ->
    {ok, cowboy_req:req(), cowboy_middleware:env()}
    | {error, integer(), any()}.
check_basic_auth(Req, Env) ->
    {value, {handler_opts, HandlerOpts1}} = lists:keysearch(handler_opts, 1, Env),
    case lists:keysearch(http_basic_auth_required, 1, HandlerOpts1) of
        false ->
            {ok, Req, Env};
        {value, {http_basic_auth_required, UserPass}} ->
            case cowboy_req:parse_header(<<"authorization">>, Req) of
                {ok, Auth, Req2} ->
                    User = proplists:get_value(user, UserPass),
                    Pass = proplists:get_value(pass, UserPass),
                    case Auth of
                        {<<"basic">>, {User, Pass}} ->
                            HandlerOpts2 = orddict:store(?HTTP_BASIC_AUTH_USER, User, HandlerOpts1),
                            Env2 = orddict:store(handler_opts, HandlerOpts2, Env),
                            lager:info("HTTP Basic Auth success: ~s", [User]),
                            {ok, Req2, Env2};
                        {<<"basic">>, {InvalidUser, _}} ->
                            lager:info("HTTP Basic Auth fail: ~s", [InvalidUser]),
                            {error, 401, Req2};
                        _ ->
                            lager:debug("unknown authorization: ~p", [Auth]),
                            {error, 401, Req2}
                    end;
                {undefined, _, Req2} ->
                    lager:debug("Auth header not present", []),
                    {error, 401, Req2};
                {error, _Reason} ->
                    lager:debug("Not authorized", []),
                    {error, 401, Req}
            end
    end.
