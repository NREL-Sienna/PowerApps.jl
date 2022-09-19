const MAX_CONCURRENT_SESSIONS = 10

struct Store{T}
    lock::ReentrantLock
    sessions::Dict{String, Session{T}}
    max_concurrent_sessions::Int
end

function Store{T}(max_concurrent_sessions=MAX_CONCURRENT_SESSIONS) where {T}
    return Store(ReentrantLock(), Dict{String, Session{T}}(), max_concurrent_sessions)
end

function add_session!(store::Store, session::Session)
    lock(store.lock) do
        if length(store.sessions) > store.max_concurrent_sessions
            error("Too many sessions are active: $(length(store.sessions))")
        end
        session.session_id in keys(store.sessions) &&
            error("$session.session_id is already stored")
        store.sessions[session.session_id] = session
        @info "Added session_id=$(session.session_id)"
    end
end

function get_session(store::Store, session_id)
    lock(store.lock) do
        !in(session_id, keys(store.sessions)) && error("$session_id is not stored")
        return store.sessions[session_id]
    end
end

function remove_session!(store::Store, session_id)
    lock(store.lock) do
        pop!(store.sessions, session_id, nothing)
        @info "Removed session_id=$session_id"
    end
end
