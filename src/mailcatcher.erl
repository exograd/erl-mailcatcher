%% Copyright (c) 2021 Bryan Frimin <bryan@frimin.fr>.
%%
%% Permission to use, copy, modify, and/or distribute this software for any
%% purpose with or without fee is hereby granted, provided that the above
%% copyright notice and this permission notice appear in all copies.
%%
%% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
%% WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
%% MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
%% SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
%% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
%% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
%% IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-module(mailcatcher).
-type messages() :: [message()].

-type message() ::
        #{id := message_id(),
          sender := binary(),
          recipients := [binary()],
          subject := binary(),
          size := binary(),
          type := binary(),
          created_at := binary(),
          format := [binary()],
          attachments := [binary()]}.

-type message_id() :: binary().

-type client_options() ::
        #{http_host => uri:host(),
          http_port => uri:port_number()}.

-type client() ::
        #{http => uri:uri()}.

-type mailcatcher_error_reason() ::
        {invalid_json_response, json:error()}
      | {invalid_response, {mhttp:status(), mhttp:body()}}
      | {invalid_request, mhttp:error_reason()}.

-spec new_client() -> client().
new_client() ->
  new_client(#{}).

-spec new_client(client_options()) -> client().
new_client(Options) ->
  Host = maps:get(host, Options, <<"localhost">>),
  Port = maps:get(port, Options, 1080),
  URI = #{scheme => <<"http">>, host => Host, port => Port},
  #{http => URI}.

-spec list_messages(client()) ->
        {ok, messages()} | {error, mailcatcher_error_reason()}.
list_messages(#{http := URI}) ->
  Request = #{method => get, target => URI#{path => <<"/messages">>}},
  case mhttp:send_request(Request) of
    {ok, #{status := 200, body := Bin}} ->
      case json:parse(Bin) of
        {ok, Data} ->
          {ok, Data};
        {error, Reason} ->
          {error, {invalid_json_response, Reason}}
      end;
    {ok, #{status := Status, body := Bin}} ->
      {error, {inavlid_response, {Status, Bin}}};
    {error, Reason} ->
      {error, {invalid_request, Reason}}
  end.

-spec delete_messages(client()) -> ok | {error, mailcatcher_error_reason()}.
delete_messages(#{http := URI}) ->
  Request = #{method => delete, target => URI#{path => <<"/messages">>}},
  case mhttp:send_request(Request) of
    {ok, #{status := 204}} ->
      ok;
    {ok, #{status := Status, body := Bin}} ->
      {error, {invalid_response, {Status, Bin}}};
    {error, Reason} ->
      {error, {invalid_request, Reason}}
  end.

