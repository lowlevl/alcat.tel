use macro_rules_attribute::apply;
use smol_macros::main;

#[apply(main!)]
async fn main() {
    println!("Hello, world!");
}
