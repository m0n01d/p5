// FileReader bindings for ReScript

type t

@new external make: unit => t = "FileReader"

type readyState =
  | @as(0) Empty
  | @as(1) Loading
  | @as(2) Done

@get external readyState: t => readyState = "readyState"
@get external result: t => Js.Nullable.t<string> = "result"
@get external error: t => Js.Nullable.t<{..}> = "error"

@send external readAsText: (t, {..}) => unit = "readAsText"
@send external readAsDataURL: (t, {..}) => unit = "readAsDataURL"
@send external readAsArrayBuffer: (t, {..}) => unit = "readAsArrayBuffer"

@set external onload: (t, {..} => unit) => unit = "onload"
@set external onerror: (t, {..} => unit) => unit = "onerror"
@set external onprogress: (t, {..} => unit) => unit = "onprogress"
