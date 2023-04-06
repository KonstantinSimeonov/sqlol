drop function if exists generate_pastes(count int);
drop type if exists paste_rec;

create type paste_rec as (
    content text,
    language varchar(20),
    created_at timestamp,
    deleted_at timestamp
);

create function generate_pastes(count int) returns setof paste_rec as
$$
    const rnd_int = (l, h) => l + Math.floor(Math.random() * (h - l))
    const rnd_elem = xs => xs[rnd_int(0, xs.length)]
    const get_sources = {
        hs: i =>
`import System.IO
main = do
    json <- readFile "${i}.json"
    line <- readLine
    writeFile "${i}.output.json" $ json ++ line
`,
        js: i =>
`import express from "express"

const app = express()
app.use("/hello", (req, res) => res.json({ msg: "que pasa" }))
app.listen(${i})
`,
        cpp: i =>
`use namespace std;
int main() {
    std::cout << i << std::endl;
}
`,
        py: i => `print(${i})`,
        css: i =>
`button.btn.btn-primary {
    width: ${i}rem;
    border: 1px dashed pink;
}
`,
        ts: i =>
`type Tuple3 = [${i}, ${i + 1}, ${i + 2}]`,
        rs: i =>
`pub fn main() {
    let xs = vec![1, 2, 3, ${i}];
    println!("{:?}", xs)
}
`
    }
    const langs = [`hs`, `js`, `cpp`, `py`, `css`, `ts`, `rs`]
    const start_ts = new Date(`01/01/2000`).getTime()
    const end_ts = new Date(`12/12/2023`).getTime()
    const pastes = Array.from(
        { length: count },
        (_, i) => {
            const lang = rnd_elem(langs)
            const created_at = rnd_int(start_ts, end_ts)
            return {
                content: get_sources[lang](i),
                language: lang,
                created_at: new Date(created_at),
                deleted_at: i % 500 ? new Date(rnd_int(created_at, end_ts)) : null
            }
        }
    )

    return pastes
$$
language plv8 immutable strict;
