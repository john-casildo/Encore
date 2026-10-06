-- =============================================================================
-- Encore – Messaging (run in Supabase SQL Editor after main setup)
-- Creates conversations and messages tables with RLS.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Conversations: one thread per renter–host pair (optionally about an instrument)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  renter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  host_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  instrument_id UUID REFERENCES public.instruments(id) ON DELETE SET NULL,
  last_message_preview TEXT,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(renter_id, host_id)
);

-- Add preview columns if table already existed
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'conversations' AND column_name = 'last_message_preview') THEN
    ALTER TABLE public.conversations ADD COLUMN last_message_preview TEXT;
    ALTER TABLE public.conversations ADD COLUMN last_message_at TIMESTAMPTZ;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_conversations_renter ON public.conversations(renter_id);
CREATE INDEX IF NOT EXISTS idx_conversations_host ON public.conversations(host_id);
CREATE INDEX IF NOT EXISTS idx_conversations_updated ON public.conversations(updated_at DESC);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "conversations_select_participant" ON public.conversations;
DROP POLICY IF EXISTS "conversations_insert_participant" ON public.conversations;

CREATE POLICY "conversations_select_participant" ON public.conversations
  FOR SELECT USING (auth.uid() = renter_id OR auth.uid() = host_id);

CREATE POLICY "conversations_insert_participant" ON public.conversations
  FOR INSERT WITH CHECK (auth.uid() = renter_id OR auth.uid() = host_id);


-- -----------------------------------------------------------------------------
-- Messages: messages belong to a conversation; sender_id is who sent it
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- If messages already existed with a different schema, add missing columns
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'conversation_id') THEN
    ALTER TABLE public.messages ADD COLUMN conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE;
    -- Make NOT NULL only if table is empty (avoid constraint violation)
    IF (SELECT count(*) FROM public.messages) = 0 THEN
      ALTER TABLE public.messages ALTER COLUMN conversation_id SET NOT NULL;
    END IF;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'sender_id') THEN
    ALTER TABLE public.messages ADD COLUMN sender_id UUID REFERENCES public.users(id) ON DELETE CASCADE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'body') THEN
    ALTER TABLE public.messages ADD COLUMN body TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'created_at') THEN
    ALTER TABLE public.messages ADD COLUMN created_at TIMESTAMPTZ DEFAULT now();
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON public.messages(created_at);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "messages_select_conversation_member" ON public.messages;
DROP POLICY IF EXISTS "messages_insert_sender" ON public.messages;

CREATE POLICY "messages_select_conversation_member" ON public.messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = messages.conversation_id
        AND (c.renter_id = auth.uid() OR c.host_id = auth.uid())
    )
  );

CREATE POLICY "messages_insert_sender" ON public.messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.renter_id = auth.uid() OR c.host_id = auth.uid())
    )
  );


-- -----------------------------------------------------------------------------
-- Optional: update conversation.updated_at when a message is inserted
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_conversation_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  UPDATE public.conversations
  SET updated_at = now(),
      last_message_preview = left(NEW.body, 100),
      last_message_at = now()
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_message_created_conversation_updated ON public.messages;
CREATE TRIGGER on_message_created_conversation_updated
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.set_conversation_updated_at();


-- =============================================================================
-- Done. Summary:
-- - conversations: renter_id, host_id, optional instrument_id; one row per pair
-- - messages: conversation_id, sender_id, body, created_at
-- - RLS: users see only their conversations and messages
-- =============================================================================
