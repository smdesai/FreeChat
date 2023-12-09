//
//  Template.swift
//  FreeChat
//
//  Created by Peter Sugihara on 10/7/23.
//

import Foundation

enum TemplateFormat: String, CaseIterable {
  case llama2
  case chatML
  case alpaca
  case vicuna
  case xgen
  case zephyr
}

protocol Template {
  var format: TemplateFormat { get }
  var stopWords: [String] { get }
  func run(systemPrompt: String, messages: [String]) -> String
}

// Mistral, Llama2Chat
struct Llama2Template: Template {
  var format = TemplateFormat.llama2
  var stopWords: [String] = ["</s>"]
  
  func run(systemPrompt: String, messages: [String]) -> String {
    var p = """
    <s>[INST] <<SYS>>
    \(systemPrompt)
    <</SYS>>
    
    \(messages.first ?? "hi") [/INST] \

    """
    
    var userTalking = false
    for message in messages.dropFirst() {
      if userTalking {
        if p.suffix(2000).contains(systemPrompt) {
          p += "<s>[INST] \(message) [/INST] "
        } else {
          // if the system prompt hasn't been covered in a while, pepper it in
          p += """
          <s>[INST] <<SYS>>
          \(systemPrompt)
          <<SYS>>
          
          \(message) [/INST]
          """
        }
      } else {
        p += "\(message) </s>"
      }
      
      userTalking.toggle()
    }
    
    return p
  }
}

// Capybara7B, Synthia
struct VicunaTemplate: Template {
  var format = TemplateFormat.vicuna
  var stopWords: [String] = ["USER", "User:", "user:", "<|im_end|>", "</s>"]

  func run(systemPrompt: String, messages: [String]) -> String {
    var p = "SYSTEM: \(systemPrompt)\n"
    
    var userTalking = true
    for message in messages {
      if userTalking {
        p.append("USER: \(message)\n")
      } else {
        p.append("ASSISTANT: \(message)\n")
      }
      userTalking.toggle()
    }
    
    if !userTalking {
      p.append("ASSISTANT: ")
    }
    
    return p
  }
}

// OpenHermes, NeuralHermes, Capybara3b
struct ChatMLTemplate: Template {
  var format = TemplateFormat.chatML
  var stopWords: [String] = ["<|im_end|>"]
  
  func run(systemPrompt: String, messages: [String]) -> String {
    var p = """
  <|im_start|>system
  \(systemPrompt)
  <|im_end|>
  
  """
    
    var userTalking = true
    for message in messages {
      p.append("""
        <|im_start|>\(userTalking ? "user" : "assistant")
        \(message)
        <|im_end|>
        
        """)
      userTalking.toggle()
    }
    
    p += "<|im_start|>assistant\n"
    
    return p
  }
}

struct AlpacaTemplate: Template {
  var format = TemplateFormat.alpaca
  var stopWords: [String] = ["### Instruction:", "### Input:", "USER:", "### Response:"]

  func run(systemPrompt: String, messages: [String]) -> String {
    var p = """
    ### Instruction:
    \(systemPrompt)
    
    Conversation so far:
    
    """
    
    var userTalking = true
    for message in messages {
      let from = userTalking ? "user" : "you"
      p.append("\(from): \(message)\n")
      userTalking.toggle()
    }
    
    p += "you:\n\nRespond to user's last line with markdown.\n\n### Response:\n"
    
    return p
  }
}

// Salesforce Xgen
struct XgenTemplate: Template {
  var format = TemplateFormat.xgen
  var stopWords: [String] = ["### Human:", "###"]

  func run(systemPrompt: String, messages: [String]) -> String {
    var p = """
    \(systemPrompt)
    
    """
    
    var userTalking = true
    for message in messages {
      let from = userTalking ? "### Human:" : "###"
      p.append("\(from) \(message)\n")
      userTalking.toggle()
    }
    
    p += "###"
    
    return p
  }
}

// Zephyr
struct ZephyrTemplate: Template {
  var format = TemplateFormat.zephyr
  var stopWords: [String] = ["<|im_end|>"]
  
  func run(systemPrompt: String, messages: [String]) -> String {
    var p = """
  <|system|>
  \(systemPrompt)</s>
  
  """
    
    var userTalking = true
    for message in messages {
      p.append("""
        <|user|>\(userTalking ? "user" : "assistant")
        \(message)
        <|/s|>
        
        """)
      userTalking.toggle()
    }
    
    p += "<|assistant|>\n"
    
    return p
  }
}
