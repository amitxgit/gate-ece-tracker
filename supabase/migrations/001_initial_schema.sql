create extension if not exists pgcrypto;

create table if not exists public.subjects (
  subject_id text primary key,
  name text not null,
  position integer not null
);

create table if not exists public.chapters (
  chapter_id text primary key,
  subject_id text not null references public.subjects(subject_id) on delete cascade,
  chapter_name text not null,
  description text not null default '',
  position integer not null
);

create table if not exists public.user_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  chapter_id text not null references public.chapters(chapter_id) on delete cascade,
  completed boolean not null default false,
  completion_date date,
  revision_count integer not null default 0 check (revision_count >= 0),
  updated_at timestamptz not null default now(),
  unique (user_id, chapter_id)
);

create table if not exists public.user_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  chapter_id text not null references public.chapters(chapter_id) on delete cascade,
  note text not null default '' check (char_length(note) <= 5000),
  updated_at timestamptz not null default now(),
  unique (user_id, chapter_id)
);

create table if not exists public.user_settings (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  theme text not null default 'system',
  exam_date date not null default date '2027-02-01',
  preferences jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.study_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date date not null,
  hours numeric(5,2) not null check (hours >= 0 and hours <= 24),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_pyq_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  subject_id text not null references public.subjects(subject_id) on delete cascade,
  solved integer not null default 0 check (solved >= 0),
  total integer not null default 0 check (total >= 0),
  updated_at timestamptz not null default now(),
  unique (user_id, subject_id),
  check (solved <= total or total = 0)
);

create table if not exists public.mock_tests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 160),
  test_date date not null,
  score numeric(5,2) not null check (score >= 0 and score <= 100),
  remarks text not null default '' check (char_length(remarks) <= 2000),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace trigger set_user_progress_updated_at before update on public.user_progress
for each row execute function public.set_updated_at();
create or replace trigger set_user_notes_updated_at before update on public.user_notes
for each row execute function public.set_updated_at();
create or replace trigger set_user_settings_updated_at before update on public.user_settings
for each row execute function public.set_updated_at();
create or replace trigger set_study_sessions_updated_at before update on public.study_sessions
for each row execute function public.set_updated_at();
create or replace trigger set_user_pyq_progress_updated_at before update on public.user_pyq_progress
for each row execute function public.set_updated_at();
create or replace trigger set_mock_tests_updated_at before update on public.mock_tests
for each row execute function public.set_updated_at();

alter table public.subjects enable row level security;
alter table public.chapters enable row level security;
alter table public.user_progress enable row level security;
alter table public.user_notes enable row level security;
alter table public.user_settings enable row level security;
alter table public.study_sessions enable row level security;
alter table public.user_pyq_progress enable row level security;
alter table public.mock_tests enable row level security;

create policy "subjects are readable" on public.subjects for select using (true);
create policy "chapters are readable" on public.chapters for select using (true);

create policy "progress select own" on public.user_progress for select using (user_id = auth.uid());
create policy "progress insert own" on public.user_progress for insert with check (user_id = auth.uid());
create policy "progress update own" on public.user_progress for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "progress delete own" on public.user_progress for delete using (user_id = auth.uid());

create policy "notes select own" on public.user_notes for select using (user_id = auth.uid());
create policy "notes insert own" on public.user_notes for insert with check (user_id = auth.uid());
create policy "notes update own" on public.user_notes for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "notes delete own" on public.user_notes for delete using (user_id = auth.uid());

create policy "settings select own" on public.user_settings for select using (user_id = auth.uid());
create policy "settings insert own" on public.user_settings for insert with check (user_id = auth.uid());
create policy "settings update own" on public.user_settings for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "settings delete own" on public.user_settings for delete using (user_id = auth.uid());

create policy "sessions select own" on public.study_sessions for select using (user_id = auth.uid());
create policy "sessions insert own" on public.study_sessions for insert with check (user_id = auth.uid());
create policy "sessions update own" on public.study_sessions for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "sessions delete own" on public.study_sessions for delete using (user_id = auth.uid());

create policy "pyq select own" on public.user_pyq_progress for select using (user_id = auth.uid());
create policy "pyq insert own" on public.user_pyq_progress for insert with check (user_id = auth.uid());
create policy "pyq update own" on public.user_pyq_progress for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "pyq delete own" on public.user_pyq_progress for delete using (user_id = auth.uid());

create policy "mocks select own" on public.mock_tests for select using (user_id = auth.uid());
create policy "mocks insert own" on public.mock_tests for insert with check (user_id = auth.uid());
create policy "mocks update own" on public.mock_tests for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "mocks delete own" on public.mock_tests for delete using (user_id = auth.uid());

insert into public.subjects (subject_id, name, position) values
('s1','Engineering Mathematics',1),
('s2','Networks, Signals and Systems',2),
('s3','Electronic Devices',3),
('s4','Analog Circuits',4),
('s5','Digital Circuits',5),
('s6','Control Systems',6),
('s7','Communications',7),
('s8','Electromagnetics',8)
on conflict (subject_id) do update set name = excluded.name, position = excluded.position;

insert into public.chapters (chapter_id, subject_id, chapter_name, description, position) values
('s1-0','s1','Linear Algebra','Vector space, basis, linear (in)dependence, matrix algebra, eigenvalues & eigenvectors, rank, existence/uniqueness of solutions.',1),
('s1-1','s1','Calculus','Mean value theorems, definite & improper integrals, partial derivatives, maxima/minima, multiple integrals, line/surface/volume integrals, Taylor series.',2),
('s1-2','s1','Differential Equations','First & higher order linear DEs, Cauchy''s & Euler''s equations, variation of parameters, PDEs, variable separable method, IVP/BVP.',3),
('s1-3','s1','Vector Analysis','Vector operations, gradient, divergence, curl, Gauss''s, Green''s & Stokes'' theorems.',4),
('s1-4','s1','Complex Analysis','Analytic functions, Cauchy''s integral theorem/formula, sequences, series, convergence tests, Taylor & Laurent series, residue theorem.',5),
('s1-5','s1','Probability & Statistics','Mean, median, mode, std deviation, combinatorial probability, binomial/Poisson/exponential/normal distributions, joint & conditional probability.',6),
('s2-0','s2','Circuit Analysis','Node/mesh analysis, superposition, Thevenin''s & Norton''s theorems, reciprocity, phasors, complex power, max power transfer, RL/RC/RLC via Laplace.',1),
('s2-1','s2','Two-Port Networks','Linear 2-port network parameters, wye-delta transformation.',2),
('s2-2','s2','Continuous-Time Signals','Fourier series & transform, sampling theorem and applications.',3),
('s2-3','s2','Discrete-Time Signals','DTFT, DFT, z-transform, discrete-time processing of continuous-time signals.',4),
('s2-4','s2','LTI Systems','Causality, stability, impulse response, convolution, poles & zeros, frequency response, group & phase delay.',5),
('s3-0','s3','Semiconductor Basics','Energy bands, intrinsic/extrinsic semiconductors, equilibrium carrier concentration, direct/indirect bandgap.',1),
('s3-1','s3','Carrier Transport','Diffusion & drift current, mobility, resistivity, generation/recombination, Poisson & continuity equations.',2),
('s3-2','s3','PN Junction & Zener Diode','',3),
('s3-3','s3','BJT','',4),
('s3-4','s3','MOS Capacitor & MOSFET','',5),
('s3-5','s3','LED, Photodiode & Solar Cell','',6),
('s4-0','s4','Diode Circuits','Clipping, clamping, rectifiers.',1),
('s4-1','s4','BJT & MOSFET Amplifiers','Biasing, AC coupling, small-signal analysis, frequency response.',2),
('s4-2','s4','Current Mirrors & Differential Amplifiers','',3),
('s4-3','s4','Op-amp Circuits','Amplifiers, summers, differentiators, integrators.',4),
('s4-4','s4','Active Filters, Schmitt Triggers & Oscillators','',5),
('s5-0','s5','Number Representations','Binary, integer & floating-point numbers.',1),
('s5-1','s5','Combinational Logic','Boolean algebra, K-map minimization, logic gates, static CMOS implementations.',2),
('s5-2','s5','Arithmetic Circuits & Converters','Arithmetic circuits, code converters, multiplexers, decoders.',3),
('s5-3','s5','Sequential Circuits','Latches, flip-flops, counters, shift registers, finite state machines.',4),
('s5-4','s5','Timing','Propagation delay, setup/hold time, critical path delay.',5),
('s5-5','s5','Data Converters','Sample & hold circuits, ADCs, DACs.',6),
('s5-6','s5','Semiconductor Memories','ROM, SRAM, DRAM.',7),
('s5-7','s5','Computer Organization','Machine instructions, addressing modes, ALU, data-path & control unit, instruction pipelining.',8),
('s6-0','s6','Basic Components & Feedback','Basic control system components, feedback principle.',1),
('s6-1','s6','Transfer Function & Block Diagrams','Transfer function, block diagram representation, signal flow graph.',2),
('s6-2','s6','Transient & Steady-State Analysis','',3),
('s6-3','s6','Frequency Response & Stability','Routh-Hurwitz and Nyquist stability criteria.',4),
('s6-4','s6','Bode & Root-Locus Plots','',5),
('s6-5','s6','Compensation','Lag, lead, and lag-lead compensation.',6),
('s6-6','s6','State Variable Model','State variable model and solution of state equations of LTI systems.',7),
('s7-0','s7','Random Processes','Autocorrelation and power spectral density, properties of white noise, filtering through LTI systems.',1),
('s7-1','s7','Analog Communications','AM/FM modulation & demodulation, spectra of AM and FM, superheterodyne receivers.',2),
('s7-2','s7','Information Theory','Entropy, mutual information, channel capacity theorem.',3),
('s7-3','s7','Digital Communications','PCM, DPCM, digital modulation (ASK/PSK/FSK/QAM), bandwidth, inter-symbol interference.',4),
('s7-4','s7','Detection & Performance','MAP, ML detection, matched filter receiver, SNR and BER.',5),
('s7-5','s7','Error Correction','Hamming codes, CRC.',6),
('s8-0','s8','Maxwell''s Equations','Differential & integral forms, boundary conditions, wave equation, Poynting vector.',1),
('s8-1','s8','Plane Waves','Reflection, refraction, polarization, phase & group velocity, propagation through media, skin depth.',2),
('s8-2','s8','Transmission Lines','Equations, characteristic impedance, impedance matching & transformation, S-parameters, Smith chart.',3),
('s8-3','s8','Waveguides, Fibers & Antennas','Rectangular & circular waveguides, optical fibers, dipole & monopole antennas, linear antenna arrays.',4)
on conflict (chapter_id) do update set
subject_id = excluded.subject_id,
chapter_name = excluded.chapter_name,
description = excluded.description,
position = excluded.position;
