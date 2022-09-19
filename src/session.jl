mutable struct Session{T}
    session_id::String
    data::T
    # TODO: Implement an Interval component to timeout and delete sessions.
    last_request::Dates.DateTime
    lock::ReentrantLock
end

Session(session_id, data::T) where {T} =
    Session{T}(session_id, data, Dates.now(), ReentrantLock())

function set_data!(session::Session, data::T) where {T}
    lock(session.lock) do
        session.data = data
    end
    return
end

get_data(session::Session) = session.data
