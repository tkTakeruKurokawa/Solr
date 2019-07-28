=begin
    ・動作確認環境
        ・macOS Mojave version10.14.5
        ・ruby 2.3.7p456
    ・使用方法
        1.「CHANGES.txt」ファイル，「README.txt」ファイル，「dokujo-tsushin」ディレクトリなどがあるディレクトリにこのファイルを配置．
        2．ターミナルで「ruby ldcc_json_converter.rb」を実行すると全記事をSolrに登録するための1つのJSONファイル(ldcc_dataset.json)が完成
=end

# Solrに登録しないファイルを回避するためのメソッド
def match(item)
    if (File.fnmatch("*ldcc*", item) || File.fnmatch("*LICENSE*", item) || File.fnmatch("*CHANGES*", item) || File.fnmatch("*README*", item) )
        return true
    else
        return false
    end
end

# 文章中にダブルクォーテーションが出てくるとSolr登録の際にエラーが出るのでシングルクォーテーションに変更
def esc_dq(line)
    lines = line.split('"')
    line = ""
    lines.each_with_index do |element, i|
        if i+1 != lines.length
            line += element + "\'"
        else
            line += element 
        end
    end

    return line
end

# 既にldcc_dataset.jsonがある場合は削除
if File.exist? "ldcc_dataset.json"
    File.delete "ldcc_dataset.json"
end

dir = ""
count = 0
# ldcc_dataset.jsonを書き込みモードで生成
File.open("ldcc_dataset.json", "a") do |f|
    f.puts "["

    # 再帰的にディレクトリ内を探索
    Dir.glob('**/*') do |item|
        # ディレクトリであった場合，カテゴリ登録のためにディレクトリ名をひかえる
        if FileTest.directory? item
            dir = item
        # ファイルであった場合，内容を解析し，ldcc_dataset.jsonに書き込み
        elsif FileTest.file? item

            # Solrに登録しないファイルを回避するためのメソッド
            if match(item) == false
                # ファイルを開く
                File.open(item) do |file|
                    puts item
                    # Jsonファイルの最後の記事の } と ]　の間に , があるとエラーが出るのでそれを回避するためにこの位置で , を書き込む
                    # 1回目の時は必要ないので書き込まないようにする
                    if count != 0
                        f.puts ","
                    end
                    f.puts "{"

                    # ファイルの内容を1行ごとに解析
                    file.each_line.with_index do |line, index|
                        # 改行文字を削除
                        line = line.chomp
                        # 最初の行はURL
                        if index == 0
                            f.print "\"id\":\"#{line}\","
                        # 2行目は日付．＋以降は不要のため　+ を Z に置き換え
                        elsif index == 1
                            lines = line.split("+")
                            line = lines[0] + "Z"
                            f.print "\"jour_date\":\"#{line}\","
                        # 3行目はタイトル． ダブルクォーテーションを回避
                        elsif index == 2
                            line = esc_dq(line)
                            f.print "\"jour_title\":\"#{line}\","
                        # 4行目は本文．ダブルクォーテーションを回避
                        elsif index == 3
                            line = esc_dq(line)                            
                            f.print "\"jour_text\":\"#{line}"
                        # 4行目以降は本文．ダブルクォーテーションを回避
                        else
                            line = esc_dq(line)
                            f.print "#{line}"
                        end
                    end
                    f.print "\","
                    # 本文を全て書き込んだ後にカテゴリを書き込み
                    f.print "\"jour_category\":\"#{dir}\""
                    f.print "}"
                    count = count + 1
                end
            end
        end
    end
    f.puts 
    f.puts "]"
end