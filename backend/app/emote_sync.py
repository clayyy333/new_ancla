"""Session-scoped, opt-in emote following. No game commands are issued here."""
import json

FOLLOW_TTL = 6.0
SAMPLE_TTL = 3.0


def scope(session):
    return session["game_id"], session["place_id"], session["job_id"]


def source_session(db, follower, user_id, cutoff):
    row = db.execute(
        """SELECT * FROM sessions WHERE user_id=? AND game_id=? AND place_id=? AND job_id=?
           ORDER BY started_at DESC,rowid DESC LIMIT 1""",
        (user_id, *scope(follower)),
    ).fetchone()
    if not row or row["ended_at"] is not None or row["last_seen"] < cutoff:
        return None
    return row


def requested(db, session, timestamp, cutoff):
    return db.execute(
        """SELECT 1 FROM emote_sync_followers f JOIN sessions s ON s.id=f.follower_session_id
           WHERE f.target_user_id=? AND f.updated_at>=? AND s.ended_at IS NULL AND s.last_seen>=?
           AND s.game_id=? AND s.place_id=? AND s.job_id=? LIMIT 1""",
        (session["user_id"], timestamp-FOLLOW_TTL, cutoff, *scope(session)),
    ).fetchone() is not None


def would_cycle(db, session, target_id, timestamp, cutoff):
    seen = {session["user_id"]}
    for _ in range(32):
        if target_id in seen:
            return True
        seen.add(target_id)
        target = source_session(db, session, target_id, cutoff)
        if not target:
            return False
        link = db.execute(
            "SELECT target_user_id FROM emote_sync_followers WHERE follower_session_id=? AND updated_at>=?",
            (target["id"], timestamp-FOLLOW_TTL),
        ).fetchone()
        if not link or link["target_user_id"] is None:
            return False
        target_id = link["target_user_id"]
    return True


def set_follow(db, session_id, sequence, target_id, timestamp):
    return db.execute(
        """INSERT INTO emote_sync_followers(follower_session_id,sequence,target_user_id,updated_at)
           VALUES(?,?,?,?) ON CONFLICT(follower_session_id) DO UPDATE SET
           sequence=excluded.sequence,target_user_id=excluded.target_user_id,updated_at=excluded.updated_at
           WHERE excluded.sequence>=emote_sync_followers.sequence""",
        (session_id, sequence, target_id, timestamp),
    ).rowcount > 0


def read_state(db, session, timestamp, cutoff):
    link = db.execute("SELECT * FROM emote_sync_followers WHERE follower_session_id=?", (session["id"],)).fetchone()
    if not link or link["target_user_id"] is None or link["updated_at"] < timestamp-FOLLOW_TTL:
        return {"ready": False, "reason": "not_following"}
    db.execute("UPDATE emote_sync_followers SET updated_at=? WHERE follower_session_id=?", (timestamp, session["id"]))
    source = source_session(db, session, link["target_user_id"], cutoff)
    if not source:
        return {"ready": False, "reason": "source_unavailable"}
    sample = db.execute("SELECT * FROM emote_sync_samples WHERE source_session_id=?", (source["id"],)).fetchone()
    if not sample or sample["updated_at"] < timestamp-SAMPLE_TTL:
        return {"ready": False, "reason": "waiting_for_source"}
    return {"ready": True, "source_session_id": source["id"], "state": json.loads(sample["payload"])}
