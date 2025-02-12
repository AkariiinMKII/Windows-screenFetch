Function New-Win10Logo() {
    [string[]] $ArtArray  =
        "",
        "                           ....::::     ",
        "                   ....::::::::::::     ",
        "          ....:::: ::::::::::::::::     ",
        "  ....:::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  ................ ................     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  '''':::::::::::: ::::::::::::::::     ",
        "          '''':::: ::::::::::::::::     ",
        "                   ''''::::::::::::     ",
        "                           ''''::::     "

    return $ArtArray
}

Function New-Win11Logo() {
    [string[]] $ArtArray =
        "",
        "  .::::::::::::::: :::::::::::::::.     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  '''''''''''''''' ''''''''''''''''     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "  :::::::::::::::: ::::::::::::::::     ",
        "   ''''''''''''''' '''''''''''''''      "

    return $ArtArray
}

# Old windows logo from WinScreeny by Nijikokun:
# https://github.com/Nijikokun/WinScreeny
Function New-WinXPLogo() {
    $esc = [char]27 # Escape character
    $x1 = "$esc[31m" # Red
    $x2 = "$esc[32m" # Green
    $x3 = "$esc[33m" # Yellow
    $x4 = "$esc[34m" # Blue
    [string[]] $ArtArray =
        "",
        "$x1         ,.=:^!^!t3Z3z.,                ",
        "$x1        :tt:::tt333EE3                  ",
        "$x1        Et:::ztt33EEE  $x2@Ee.,      ..,   ",
        "$x1       ;tt:::tt333EE7 $x2;EEEEEEttttt33#   ",
        "$x1      :Et:::zt333EEQ.$x2 SEEEEEttttt33QL   ",
        "$x1      it::::tt333EEF $x2@EEEEEEttttt33F    ",
        "$x1     ;3=*^``````'*4EEV $x2`:EEEEEEttttt33@.    ",
        "$x4     ,.=::::it=., $x1`` $x2@EEEEEEtttz33QF     ",
        "$x4    ;::::::::zt33)   $x2'4EEEtttji3P*      ",
        "$x4   :t::::::::tt33.$x3`:Z3z..  $x2```` $x3,..g.      ",
        "$x4   i::::::::zt33F$x3 AEEEtttt::::ztF       ",
        "$x4  ;:::::::::t33V $x3;EEEttttt::::t3        ",
        "$x4  E::::::::zt33L $x3@EEEtttt::::z3F        ",
        "$x4 {3=*^``````'*4E3) $x3;EEEtttt:::::tZ``        ",
        "$x4             `` $x3`:EEEEtttt::::z7          ",
        "$x3                 $x3'VEzjt:;;z>*``          "

    return $ArtArray
}

Function New-MacLogo() {
    $esc = [char]27 # Escape character
    $a1 = "$esc[32m" # Green
    $a2 = "$esc[93m" # Bright Yellow
    $a3 = "$esc[33m" # Yellow
    $a4 = "$esc[31m" # Red
    $a5 = "$esc[35m" # Magenta
    $a6 = "$esc[34m" # Blue
    [string[]] $ArtArray =
        "",
        "$a1                   -/+:.                ",
        "$a1                  :++++.                ",
        "$a1                 /+++/.                 ",
        "$a1         .:-::- .+/:-````.::-             ",
        "$a1      .:/++++++/::::/++++++/:``          ",
        "$a2    .:///////////////////////:``         ",
        "$a2    ////////////////////////``           ",
        "$a3   -+++++++++++++++++++++++``            ",
        "$a3   /++++++++++++++++++++++/             ",
        "$a4   /sssssssssssssssssssssss.            ",
        "$a4   :ssssssssssssssssssssssss-           ",
        "$a5    osssssssssssssssssssssssso/``        ",
        "$a5    ``syyyyyyyyyyyyyyyyyyyyyyyy+``        ",
        "$a6     ``ossssssssssssssssssssss/          ",
        "$a6       :ooooooooooooooooooo+.           ",
        "$a6        ``:+oo+/:'  ':/+o+/-             "

    return $ArtArray
}
