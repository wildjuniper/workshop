set quiet

help:
    just --list

update home:   
    stow --target ~ --dir homes {{home}}
    @echo "Linked \`homes/{{home}}\` to your home directory"
