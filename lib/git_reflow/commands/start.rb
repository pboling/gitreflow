desc 'Start will create a new feature branch and setup remote tracking'
long_desc <<LONGTIME
  Performs the following:\n
  \t$ git pull origin <current_branch>\n
  \t$ git push origin <current_branch>:refs/heads/[new_feature_branch]\n
  \t$ git checkout --track -b [new_feature_branch] origin/[new_feature_branch]\n
LONGTIME
arg_name '[new-feature-branch-name] - name of the new feature branch'
command :start do |c|
  c.desc 'Use an existing trello card as a reference'
  c.switch :trello

  c.action do |global_options, options, args|
    if options[:trello]
      GitReflow.setup_trello
      # Gather Next cards
      next_list = GitReflow.trello_next_list
      in_progress_list = GitReflow.trello_in_progress_list
      next_up_cards = next_list.cards.first(5)
      unless next_list.nil?
        selected = choose do |menu|
          menu.prompt = "Choose a task to start: "

          next_up_cards.each do |card|
            menu.choice("#{card.name} [#{card.short_id}]")
          end
        end
        selected_card_id = selected[/\[\d+\]/][1..-2]
        selected_card = next_up_cards.select {|card| card.short_id.to_s == selected_card_id.to_s }.first

        if args.empty?
          branch_name = ask("Enter a branch name: ")
          raise "usage: git-reflow start [new-branch-name]" if branch_name.empty?
        else
          branch_name = args[0]
        end

        GitReflow.run_command_with_label "git pull origin #{GitReflow.current_branch}"
        GitReflow.run_command_with_label "git push origin #{GitReflow.current_branch}:refs/heads/#{branch_name}"
        GitReflow.run_command_with_label "git checkout --track -b #{branch_name} origin/#{branch_name}"

        GitReflow::Config.set "branch.#{branch_name}.trello-card-id", selected_card.id.to_s, local: true
        GitReflow::Config.set "branch.#{branch_name}.trello-card-short-id", selected_card.short_id.to_s, local: true
        GitReflow::Config.set "branch.#{branch_name}.trello-task-name", selected_card.name.to_s, local: true

        GitReflow.say "Adding you as a member of card ##{selected_card.short_id}", :notice
        selected_card.add_member(GitReflow.current_trello_member)
        GitReflow.say "Moving card ##{selected_card.short_id} to 'In Progress' list", :notice
        selected_card.move_to_list( in_progress_list )
      end
    elsif args.empty?
      raise "usage: git-reflow start [new-branch-name]"
    else
      `git pull origin #{GitReflow.current_branch}`
      `git push origin #{GitReflow.current_branch}:refs/heads/#{args[0]}`
      `git checkout --track -b #{args[0]} origin/#{args[0]}`
    end
  end
end
